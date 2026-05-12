-- ============================================================
--  Base de datos: bdzara
--  Sistema de venta de ropa
--  Generado: 2026-05-12
-- ============================================================

CREATE DATABASE IF NOT EXISTS bdzara
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE bdzara;

-- ------------------------------------------------------------
-- 1. CATEGORIA
--    Se crea primero porque PRODUCTO depende de ella.
--    Autorreferencia para jerarquías (Ropa > Hombre > Camisas).
-- ------------------------------------------------------------
CREATE TABLE categoria (
    id                  CHAR(36)        NOT NULL DEFAULT (UUID()),
    nombre              VARCHAR(100)    NOT NULL,
    descripcion         TEXT,
    categoria_padre_id  CHAR(36)        NULL,
    activa              BOOLEAN         NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_categoria PRIMARY KEY (id),
    CONSTRAINT fk_categoria_padre
        FOREIGN KEY (categoria_padre_id)
        REFERENCES categoria (id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

-- ------------------------------------------------------------
-- 2. PROVEEDOR
--    Se crea antes que PRODUCTO porque este la referencia.
-- ------------------------------------------------------------
CREATE TABLE proveedor (
    id          CHAR(36)        NOT NULL DEFAULT (UUID()),
    nombre      VARCHAR(150)    NOT NULL,
    contacto    VARCHAR(100),
    email       VARCHAR(150),
    telefono    VARCHAR(20),
    pais        VARCHAR(60),
    CONSTRAINT pk_proveedor PRIMARY KEY (id)
);

-- ------------------------------------------------------------
-- 3. CLIENTE
-- ------------------------------------------------------------
CREATE TABLE cliente (
    id              CHAR(36)        NOT NULL DEFAULT (UUID()),
    nombre          VARCHAR(100)    NOT NULL,
    email           VARCHAR(150)    NOT NULL,
    telefono        VARCHAR(20),
    direccion       TEXT,
    fecha_registro  DATE            NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT pk_cliente  PRIMARY KEY (id),
    CONSTRAINT uq_cliente_email UNIQUE (email)
);

-- ------------------------------------------------------------
-- 4. PRODUCTO
-- ------------------------------------------------------------
CREATE TABLE producto (
    id              CHAR(36)        NOT NULL DEFAULT (UUID()),
    categoria_id    CHAR(36)        NOT NULL,
    proveedor_id    CHAR(36),
    nombre          VARCHAR(150)    NOT NULL,
    descripcion     TEXT,
    precio_base     DECIMAL(10,2)   NOT NULL CHECK (precio_base >= 0),
    activo          BOOLEAN         NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_producto PRIMARY KEY (id),
    CONSTRAINT fk_producto_categoria
        FOREIGN KEY (categoria_id)
        REFERENCES categoria (id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_producto_proveedor
        FOREIGN KEY (proveedor_id)
        REFERENCES proveedor (id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

-- ------------------------------------------------------------
-- 5. VARIANTE
--    Cada fila es una combinación única de producto + talla + color.
-- ------------------------------------------------------------
CREATE TABLE variante (
    id              CHAR(36)        NOT NULL DEFAULT (UUID()),
    producto_id     CHAR(36)        NOT NULL,
    talla           VARCHAR(10)     NOT NULL,
    color           VARCHAR(50)     NOT NULL,
    sku             VARCHAR(50)     NOT NULL,
    precio_extra    DECIMAL(10,2)   NOT NULL DEFAULT 0.00 CHECK (precio_extra >= 0),
    CONSTRAINT pk_variante  PRIMARY KEY (id),
    CONSTRAINT uq_variante_sku UNIQUE (sku),
    CONSTRAINT fk_variante_producto
        FOREIGN KEY (producto_id)
        REFERENCES producto (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- ------------------------------------------------------------
-- 6. INVENTARIO
--    Relación 1-a-1 con VARIANTE.
-- ------------------------------------------------------------
CREATE TABLE inventario (
    id                   CHAR(36)    NOT NULL DEFAULT (UUID()),
    variante_id          CHAR(36)    NOT NULL,
    cantidad             INT         NOT NULL DEFAULT 0 CHECK (cantidad >= 0),
    stock_minimo         INT         NOT NULL DEFAULT 5  CHECK (stock_minimo >= 0),
    ultima_actualizacion TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP
                                              ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_inventario PRIMARY KEY (id),
    CONSTRAINT uq_inventario_variante UNIQUE (variante_id),
    CONSTRAINT fk_inventario_variante
        FOREIGN KEY (variante_id)
        REFERENCES variante (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- ------------------------------------------------------------
-- 7. PEDIDO
-- ------------------------------------------------------------
CREATE TABLE pedido (
    id               CHAR(36)      NOT NULL DEFAULT (UUID()),
    cliente_id       CHAR(36)      NOT NULL,
    fecha            TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado           ENUM(
                       'pendiente',
                       'procesando',
                       'enviado',
                       'entregado',
                       'cancelado'
                     )             NOT NULL DEFAULT 'pendiente',
    total            DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (total >= 0),
    metodo_pago      VARCHAR(50)   NOT NULL,
    direccion_envio  TEXT,
    CONSTRAINT pk_pedido PRIMARY KEY (id),
    CONSTRAINT fk_pedido_cliente
        FOREIGN KEY (cliente_id)
        REFERENCES cliente (id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- ------------------------------------------------------------
-- 8. DETALLE_PEDIDO
-- ------------------------------------------------------------
CREATE TABLE detalle_pedido (
    id               CHAR(36)      NOT NULL DEFAULT (UUID()),
    pedido_id        CHAR(36)      NOT NULL,
    variante_id      CHAR(36)      NOT NULL,
    cantidad         INT           NOT NULL CHECK (cantidad > 0),
    precio_unitario  DECIMAL(10,2) NOT NULL CHECK (precio_unitario >= 0),
    descuento        DECIMAL(5,2)  NOT NULL DEFAULT 0.00
                                   CHECK (descuento BETWEEN 0 AND 100),
    CONSTRAINT pk_detalle_pedido PRIMARY KEY (id),
    CONSTRAINT fk_detalle_pedido_pedido
        FOREIGN KEY (pedido_id)
        REFERENCES pedido (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_detalle_pedido_variante
        FOREIGN KEY (variante_id)
        REFERENCES variante (id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- ------------------------------------------------------------
-- 9. DEVOLUCION
-- ------------------------------------------------------------
CREATE TABLE devolucion (
    id               CHAR(36)      NOT NULL DEFAULT (UUID()),
    pedido_id        CHAR(36)      NOT NULL,
    motivo           TEXT          NOT NULL,
    estado           ENUM(
                       'solicitada',
                       'aprobada',
                       'rechazada',
                       'completada'
                     )             NOT NULL DEFAULT 'solicitada',
    fecha            DATE          NOT NULL DEFAULT (CURRENT_DATE),
    monto_reembolso  DECIMAL(10,2) CHECK (monto_reembolso >= 0),
    CONSTRAINT pk_devolucion PRIMARY KEY (id),
    CONSTRAINT fk_devolucion_pedido
        FOREIGN KEY (pedido_id)
        REFERENCES pedido (id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- ============================================================
--  ÍNDICES para optimizar consultas frecuentes
-- ============================================================
CREATE INDEX idx_producto_categoria  ON producto      (categoria_id);
CREATE INDEX idx_producto_proveedor  ON producto      (proveedor_id);
CREATE INDEX idx_variante_producto   ON variante      (producto_id);
CREATE INDEX idx_pedido_cliente      ON pedido        (cliente_id);
CREATE INDEX idx_pedido_estado       ON pedido        (estado);
CREATE INDEX idx_pedido_fecha        ON pedido        (fecha);
CREATE INDEX idx_detalle_pedido      ON detalle_pedido(pedido_id);
CREATE INDEX idx_detalle_variante    ON detalle_pedido(variante_id);
CREATE INDEX idx_devolucion_pedido   ON devolucion    (pedido_id);

-- ============================================================
--  DATOS DE PRUEBA
-- ============================================================

-- Categorías (con jerarquía)
INSERT INTO categoria (id, nombre, descripcion, categoria_padre_id) VALUES
  ('cat-001', 'Ropa',       'Todas las prendas de vestir',    NULL),
  ('cat-002', 'Hombre',     'Ropa para hombre',               'cat-001'),
  ('cat-003', 'Mujer',      'Ropa para mujer',                'cat-001'),
  ('cat-004', 'Camisas',    'Camisas y playeras de hombre',   'cat-002'),
  ('cat-005', 'Vestidos',   'Vestidos casuales y formales',   'cat-003');

-- Proveedores
INSERT INTO proveedor (id, nombre, contacto, email, pais) VALUES
  ('prov-001', 'Textiles del Norte SA',  'Luis Méndez',  'luis@texnorte.mx',  'México'),
  ('prov-002', 'FashionLine Import',     'Ana Flores',   'ana@fashionline.com','China');

-- Clientes
INSERT INTO cliente (id, nombre, email, telefono, direccion) VALUES
  ('cli-001', 'María García',    'maria@email.com',  '6561234567', 'Av. Juárez 101, Chihuahua'),
  ('cli-002', 'Carlos Ramos',    'carlos@email.com', '6569876543', 'Calle Lerdo 45, Juárez');

-- Productos
INSERT INTO producto (id, categoria_id, proveedor_id, nombre, precio_base) VALUES
  ('prod-001', 'cat-004', 'prov-001', 'Playera polo clásica',  299.00),
  ('prod-002', 'cat-005', 'prov-002', 'Vestido casual floral', 549.00);

-- Variantes
INSERT INTO variante (id, producto_id, talla, color, sku) VALUES
  ('var-001', 'prod-001', 'M',  'Blanco', 'POLO-M-BLA'),
  ('var-002', 'prod-001', 'L',  'Negro',  'POLO-L-NEG'),
  ('var-003', 'prod-002', 'S',  'Floral', 'VEST-S-FLO');

-- Inventario
INSERT INTO inventario (id, variante_id, cantidad, stock_minimo) VALUES
  ('inv-001', 'var-001', 50, 10),
  ('inv-002', 'var-002', 30, 10),
  ('inv-003', 'var-003', 20,  5);

-- Pedido
INSERT INTO pedido (id, cliente_id, estado, total, metodo_pago, direccion_envio) VALUES
  ('ped-001', 'cli-001', 'entregado', 598.00, 'tarjeta', 'Av. Juárez 101, Chihuahua');

-- Detalle del pedido
INSERT INTO detalle_pedido (id, pedido_id, variante_id, cantidad, precio_unitario) VALUES
  ('det-001', 'ped-001', 'var-001', 2, 299.00);

-- ============================================================
--  FIN DEL SCRIPT
-- ============================================================
