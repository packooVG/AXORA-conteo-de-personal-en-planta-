-- ============================================================
-- SETUP SUPABASE PARA AXORA
-- Ejecuta esto en SQL Editor de Supabase
-- ============================================================

-- 1. Tabla de plantas
CREATE TABLE IF NOT EXISTS plants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  config JSONB DEFAULT '{"whatsapp":"","intervalo":15,"planta":"ALIMENTOS Y SALSAS"}',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 2. Tabla de relación usuario-planta
CREATE TABLE IF NOT EXISTS plant_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  plant_id UUID REFERENCES plants(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, plant_id)
);

-- 3. Tabla de contadores
CREATE TABLE IF NOT EXISTS counts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plant_id UUID REFERENCES plants(id) ON DELETE CASCADE NOT NULL,
  categoria TEXT NOT NULL,
  tipo TEXT NOT NULL CHECK (tipo IN ('interno', 'externo')),
  valor INTEGER DEFAULT 0 CHECK (valor >= 0),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(plant_id, categoria, tipo)
);

-- 4. Tabla de logs
CREATE TABLE IF NOT EXISTS logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  plant_id UUID REFERENCES plants(id) ON DELETE CASCADE NOT NULL,
  accion TEXT,
  categoria TEXT,
  tipo TEXT,
  valor_anterior INTEGER,
  valor_nuevo INTEGER,
  created_at TIMESTAMP DEFAULT NOW()
);

-- 5. Tabla de reportes
CREATE TABLE IF NOT EXISTS reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plant_id UUID REFERENCES plants(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  snapshot JSONB,
  imagen_url TEXT,
  whatsapp_enviado BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- ROW LEVEL SECURITY (RLS) - SEGURIDAD
-- ============================================================

-- Habilitar RLS en todas las tablas
ALTER TABLE plants ENABLE ROW LEVEL SECURITY;
ALTER TABLE plant_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE counts ENABLE ROW LEVEL SECURITY;
ALTER TABLE logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- Políticas para plants
CREATE POLICY "Users can view their plants" ON plants
  FOR SELECT USING (
    id IN (SELECT plant_id FROM plant_users WHERE user_id = auth.uid())
  );

-- Políticas para plant_users
CREATE POLICY "Users can view their assignments" ON plant_users
  FOR SELECT USING (user_id = auth.uid());

-- Políticas para counts
CREATE POLICY "Users can view counts of their plants" ON counts
  FOR SELECT USING (
    plant_id IN (SELECT plant_id FROM plant_users WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can update counts of their plants" ON counts
  FOR UPDATE USING (
    plant_id IN (SELECT plant_id FROM plant_users WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can insert counts to their plants" ON counts
  FOR INSERT WITH CHECK (
    plant_id IN (SELECT plant_id FROM plant_users WHERE user_id = auth.uid())
  );

-- Políticas para logs
CREATE POLICY "Users can view logs of their plants" ON logs
  FOR SELECT USING (
    plant_id IN (SELECT plant_id FROM plant_users WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can insert logs to their plants" ON logs
  FOR INSERT WITH CHECK (
    plant_id IN (SELECT plant_id FROM plant_users WHERE user_id = auth.uid())
    AND user_id = auth.uid()
  );

-- Políticas para reports
CREATE POLICY "Users can view reports of their plants" ON reports
  FOR SELECT USING (
    plant_id IN (SELECT plant_id FROM plant_users WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can insert reports to their plants" ON reports
  FOR INSERT WITH CHECK (
    plant_id IN (SELECT plant_id FROM plant_users WHERE user_id = auth.uid())
    AND user_id = auth.uid()
  );

-- ============================================================
-- ÍNDICES PARA RENDIMIENTO
-- ============================================================

CREATE INDEX idx_plant_users_user_id ON plant_users(user_id);
CREATE INDEX idx_plant_users_plant_id ON plant_users(plant_id);
CREATE INDEX idx_counts_plant_id ON counts(plant_id);
CREATE INDEX idx_logs_plant_id ON logs(plant_id);
CREATE INDEX idx_reports_plant_id ON reports(plant_id);

-- ============================================================
-- DATOS DE PRUEBA (opcional - comenta si no quieres)
-- ============================================================

-- Insertar una planta de prueba
-- INSERT INTO plants (name, config) VALUES (
--   'Planta Test',
--   '{"whatsapp":"5215512345678","intervalo":15,"planta":"ALIMENTOS Y SALSAS"}'
-- );

-- Para obtener el ID de la planta creada, ejecuta:
-- SELECT id FROM plants WHERE name = 'Planta Test';

-- Luego usa ese ID para crear la relación con tu usuario
-- (deberás reemplazar 'user-uuid-aqui' por tu ID de usuario)
-- INSERT INTO plant_users (user_id, plant_id) VALUES (
--   'user-uuid-aqui',
--   (SELECT id FROM plants WHERE name = 'Planta Test')
-- );

-- Insertar contadores iniciales
-- INSERT INTO counts (plant_id, categoria, tipo, valor) 
-- SELECT 
--   (SELECT id FROM plants LIMIT 1),
--   cat,
--   tip,
--   0
-- FROM (
--   VALUES 
--   ('Directivos', 'interno'),
--   ('Administrativos', 'interno'),
--   ('Planta', 'interno'),
--   ('Cursos', 'interno'),
--   ('Transportistas', 'externo'),
--   ('Visitantes', 'externo'),
--   ('Contratistas', 'externo'),
--   ('Proveedores', 'externo'),
--   ('Practicantes', 'externo')
-- ) AS t(cat, tip);
