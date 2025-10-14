# Posts with Creator Names Implementation

## Overview
This implementation uses **Option 1 (Batch Fetch User Names)** to efficiently get creator names for posts by batching user lookups and caching results.

## How It Works

### 1. Database Setup
Make sure your Supabase database has these tables:
- `posts` table with `user_id` field
- `profiles` table (or `users`) with `id` and `name` fields

### 2. Code Changes Made

#### LocationService (`location_service.dart`)
```dart
// Added method to batch fetch user names
Future<Map<String, String>> getUserNames(List<String> userIds) async {
  final response = await _supabase
      .from('profiles') // Change to 'users' if that's your table name
      .select('id, name')
      .inFilter('id', userIds);
  
  final Map<String, String> userNames = {};
  for (final row in response as List) {
    userNames[row['id'] as String] = row['name'] as String? ?? 'Unknown User';
  }
  return userNames;
}
```

#### PostModel (`models/post_model.dart`)
```dart
class PostModel {
  // ... existing fields ...
  final String? creatorName; // Added this field
  
  // Updated constructor, fromJson, copyWith methods
}
```

#### PostsManager (`features/map/presentation/providers/posts_manager.dart`)
```dart
// Enhanced to automatically enrich posts with creator names
void subscribeToPostsUpdates({
  required String circleId,
  required Function(Map<String, PostModel>) onPostsUpdate,
}) {
  _locationService.subscribeToPost(
    circleId: circleId,
    onPostsUpdate: (posts) async {
      // Automatically enrich with creator names
      final enrichedPosts = await enrichPostsWithCreatorNames(posts);
      onPostsUpdate(enrichedPosts);
    },
  );
}
```

### 3. Key Features

#### ✅ **Automatic Enrichment**
Posts are automatically enriched with creator names when received via real-time subscription.

#### ✅ **Efficient Batching** 
User names are fetched in batches, not one-by-one:
```dart
// Instead of N queries for N posts, just 1 query for all unique users
final userIds = ['user1', 'user2', 'user3'];
final userNames = await getUserNames(userIds); // Single database call
```

#### ✅ **Smart Caching**
User names are cached for 10 minutes to avoid repeated database calls:
```dart
// Cache automatically manages itself
final userNames1 = await getUserNames(['user1']); // Database call
final userNames2 = await getUserNames(['user1']); // From cache (if < 10 min)
```

#### ✅ **Fallback Handling**
If user name lookup fails, shows "Unknown User" instead of breaking.

## Usage Examples

### In Your UI Components
```dart
// Posts now automatically have creator names
Widget buildPost(PostModel post) {
  return ListTile(
    title: Text(post.name),
    subtitle: Text('By: ${post.creatorName ?? "Unknown User"}'),
    // ... rest of your UI
  );
}
```

### In Your MapProvider
```dart
// Your existing code already works! Posts from subscribeToPostsUpdates 
// now automatically include creator names
final posts = ref.watch(mapNotifierProvider).posts;
// posts['postId'].creatorName is now available
```

### Manual Fetching (if needed)
```dart
final postsManager = PostsManager();

// Get specific posts with creator names
final enrichedPosts = await postsManager.enrichPostsWithCreatorNames(rawPosts);

// Or get user names directly
final userNames = await postsManager.getUserNames(['user1', 'user2']);
```

## Performance Benefits

1. **Reduced Database Calls**: Batch fetching vs individual queries
2. **Caching**: Repeated user lookups use cache instead of database
3. **Automatic**: No manual management needed in UI code
4. **Efficient**: Only fetches missing user names, reuses cached ones

## Database Table Requirements

Make sure your `profiles` table exists with this structure:
```sql
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

Or if you use a `users` table, update the table name in `LocationService.getUserNames()`.

## Troubleshooting

### Issue: "Table 'profiles' doesn't exist"
**Solution**: Change `'profiles'` to your actual users table name in `LocationService.getUserNames()`

### Issue: Creator names not showing
**Solution**: 
1. Check if `profiles` table has data for the user IDs
2. Verify the table structure matches expected columns (`id`, `name`)
3. Check Supabase RLS policies allow reading from profiles table

### Issue: Performance problems
**Solution**: 
1. Cache is working automatically
2. Consider adding database indexes on `profiles.id` if not already present
3. Monitor cache hit rates in logs

## Next Steps

1. **Test the implementation** with real data
2. **Adjust table name** in `getUserNames()` if needed  
3. **Add more user fields** if needed (avatar, role, etc.)
4. **Monitor performance** and adjust cache duration if needed