-- Create geofences table for places/geofences functionality
CREATE TABLE geofences (
    geofence_id TEXT PRIMARY KEY,
    circle_id TEXT NOT NULL,
    center_geography TEXT NOT NULL, -- WKT format: "POINT(lat lon)"
    radius_m NUMERIC NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    FOREIGN KEY (circle_id) REFERENCES circles(circle_id) ON DELETE CASCADE
);

-- Create index for better query performance
CREATE INDEX idx_geofences_circle_id ON geofences(circle_id);

-- Insert some sample geofences for testing (optional)
INSERT INTO geofences (geofence_id, circle_id, center_geography, radius_m, title, message) VALUES
('sample-geo-1', (SELECT circle_id FROM circles LIMIT 1), 'POINT(3.1390 101.6869)', 500, 'KLCC', 'You are now near KLCC'),
('sample-geo-2', (SELECT circle_id FROM circles LIMIT 1), 'POINT(3.1478 101.6953)', 300, 'Pavilion KL', 'You are now near Pavilion KL');