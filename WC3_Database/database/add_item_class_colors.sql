BEGIN;

CREATE TABLE IF NOT EXISTS ui_color_scheme (
    id SERIAL PRIMARY KEY,
    element_type VARCHAR(50) NOT NULL,
    element_name VARCHAR(100) NOT NULL,
    color_hex VARCHAR(7) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(element_type, element_name)
);

INSERT INTO ui_color_scheme (element_type, element_name, color_hex, description)
VALUES
    ('class', 'Ability', '#00CED1', 'Ability items'),
    ('class', 'Skill', '#1E90FF', 'Skill items'),
    ('class', 'Quest', '#FFFF00', 'Quest items'),
    ('class', 'Miscellaneous', '#D3D3D3', 'Miscellaneous items'),
    ('class', 'Other', '#D3D3D3', 'Other items'),
    ('class', 'Head Armor', '#C0C0C0', 'Head armor items'),
    ('class', 'Chest Armor', '#B0C4DE', 'Chest armor items'),
    ('class', 'Leg Armor', '#A9B7C6', 'Leg armor items'),
    ('class', 'Foot Armor', '#CD853F', 'Foot armor items'),
    ('class', 'Hand Armor', '#DEB887', 'Hand armor items'),
    ('class', 'Main Hand Weapon', '#A52A2A', 'Main-hand weapon items'),
    ('class', 'Off Hand Weapon', '#8B4513', 'Off-hand weapon items'),
    ('class', 'Two-Hand Weapon', '#B22222', 'Two-hand weapon items'),
    ('class', 'Ring', '#FFD700', 'Ring items'),
    ('class', 'Amulet', '#40E0D0', 'Amulet items'),
    ('class', 'Trinket', '#DA70D6', 'Trinket items'),
    ('class', 'Back', '#708090', 'Back items')
ON CONFLICT (element_type, element_name) DO NOTHING;

COMMIT;
