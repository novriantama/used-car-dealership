-- Create schema for used car storefront

CREATE TABLE IF NOT EXISTS admins (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS vehicles (
    id SERIAL PRIMARY KEY,
    make VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    year INT NOT NULL,
    price BIGINT NOT NULL,
    transmission VARCHAR(20) NOT NULL,
    fuel_type VARCHAR(20) NOT NULL,
    mileage INT NOT NULL,
    engine_capacity INT NOT NULL,
    color VARCHAR(30) NOT NULL,
    plate_type VARCHAR(10) NOT NULL,
    tax_status VARCHAR(20) NOT NULL,
    tax_expiry_date DATE NOT NULL,
    location VARCHAR(100) NOT NULL,
    inspection_engine INT NOT NULL DEFAULT 100,
    inspection_interior INT NOT NULL DEFAULT 100,
    inspection_exterior INT NOT NULL DEFAULT 100,
    inspection_notes TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'Available',
    image_urls TEXT[] NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Seed initial vehicles
INSERT INTO vehicles (
    make, model, year, price, transmission, fuel_type, mileage, engine_capacity, 
    color, plate_type, tax_status, tax_expiry_date, location, 
    inspection_engine, inspection_interior, inspection_exterior, inspection_notes, 
    status, image_urls
) VALUES 
(
    'Toyota', 'Avanza 1.3 G M/T', 2020, 180000000, 'Manual', 'Petrol', 45000, 1329, 
    'Silver Metallic', 'Ganjil', 'Aktif', '2027-08-15', 'Jakarta Selatan', 
    94, 96, 92, 'Mesin halus, AC dingin, interior orisinil bersih, cat body ada lecet halus pemakaian wajar.', 
    'Available', ARRAY['https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&q=80&w=600']
),
(
    'Honda', 'Civic 1.5 Turbo Sedan A/T', 2019, 385000000, 'Automatic', 'Petrol', 38000, 1498, 
    'Crystal Black Pearl', 'Genap', 'Aktif', '2026-11-20', 'Jakarta Pusat', 
    98, 97, 95, 'Kondisi sangat terawat, service record bengkel resmi Honda, kaki-kaki sunyi, siap pakai.', 
    'Available', ARRAY['https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?auto=format&fit=crop&q=80&w=600']
),
(
    'Hyundai', 'Creta 1.5 Prime A/T', 2022, 310000000, 'Automatic', 'Petrol', 18000, 1497, 
    'Dragon Red Pearl', 'Ganjil', 'Aktif', '2027-02-10', 'Tangerang', 
    99, 99, 98, 'Seperti baru, tangan pertama dari baru, panoramic sunroof berfungsi normal, garansi resmi aktif.', 
    'Available', ARRAY['https://images.unsplash.com/photo-1617788138017-80ad40651399?auto=format&fit=crop&q=80&w=600']
),
(
    'Mitsubishi', 'Pajero Sport 2.4 Dakar A/T', 2018, 420000000, 'Automatic', 'Diesel', 72000, 2442, 
    'Titanium Gray', 'Genap', 'Aktif', '2026-09-05', 'Bekasi', 
    92, 94, 91, 'Mesin diesel gahar, tarikan mantap, matic responsif, jok kulit tidak ada yang sobek.', 
    'Available', ARRAY['https://images.unsplash.com/photo-1533559662493-6bc96fa0e88d?auto=format&fit=crop&q=80&w=600']
),
(
    'Wuling', 'Air EV Long Range', 2023, 220000000, 'Automatic', 'Electric', 8000, 0, 
    'Galaxy Blue', 'Genap', 'Aktif', '2027-06-25', 'Jakarta Barat', 
    100, 98, 97, 'Bebas aturan ganjil-genap Jakarta, baterai sehat 100%, wall charger include, plat nomor genap.', 
    'Available', ARRAY['https://images.unsplash.com/photo-1563720223185-11003d516935?auto=format&fit=crop&q=80&w=600']
),
(
    'Honda', 'Brio 1.2 Satya E CVT', 2021, 145000000, 'Automatic', 'Petrol', 29000, 1199, 
    'Taffeta White', 'Ganjil', 'Kedaluwarsa', '2026-03-12', 'Depok', 
    95, 93, 89, 'Pajak off Maret 2026, bisa dibantu proses balik nama/perpanjang, mobil lincah irit bahan bakar.', 
    'Available', ARRAY['https://images.unsplash.com/photo-1605559424843-9e4c228bf1c2?auto=format&fit=crop&q=80&w=600']
);

-- Transactions table for POS (Point of Sale) records
CREATE TABLE IF NOT EXISTS transactions (
    id SERIAL PRIMARY KEY,
    vehicle_id INT NOT NULL REFERENCES vehicles(id),
    buyer_name VARCHAR(150) NOT NULL,
    buyer_phone VARCHAR(20) NOT NULL,
    buyer_id_number VARCHAR(20) NOT NULL,
    payment_method VARCHAR(20) NOT NULL CHECK (payment_method IN ('Cash', 'KPR', 'Leasing')),
    sale_price BIGINT NOT NULL,
    down_payment BIGINT NOT NULL DEFAULT 0,
    installment_months INT NOT NULL DEFAULT 0,
    installment_amount BIGINT NOT NULL DEFAULT 0,
    notes TEXT,
    created_by VARCHAR(50) NOT NULL,
    sold_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
