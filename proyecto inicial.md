Aquí tienes el modelo entidad-relación para un sistema de venta de ropa. Te explico cada entidad y su propósito:
<img width="635" height="712" alt="image" src="https://github.com/user-attachments/assets/785a5501-3faa-4595-89b7-09bebb09e2a4" />

**Núcleo del negocio**

`CLIENTE` almacena los datos de quien compra. `PEDIDO` representa cada transacción, vinculada al cliente, con su estado (pendiente, enviado, entregado) y método de pago. `DETALLE_PEDIDO` es la tabla puente que guarda qué variantes y en qué cantidad van en cada pedido.

**Catálogo de productos**

`PRODUCTO` es el artículo en términos generales (ej. "Playera polo"). `VARIANTE` desglosa cada combinación de talla y color posible, con su propio SKU y stock. Esta separación es clave en ropa porque un mismo producto puede tener decenas de variantes. `CATEGORIA` permite jerarquías (Ropa > Hombre > Camisas) gracias al campo `categoria_padre_id` autorreferencial.

**Operaciones**

`PROVEEDOR` rastrea de dónde viene cada producto. `INVENTARIO` lleva el control de existencias por variante con fecha de última actualización, útil para auditorías. `DEVOLUCION` gestiona devoluciones ligadas a un pedido específico.

**Relaciones clave a tener en cuenta**

- Un cliente puede tener muchos pedidos, pero cada pedido pertenece a un solo cliente.
- Un producto tiene muchas variantes; cada variante tiene exactamente un registro de inventario.
- Los pedidos generan detalles por cada variante comprada; ahí se guarda el precio unitario al momento de la venta (no el precio actual del producto, que puede cambiar).

¿Quieres profundizar en alguna entidad, agregar funcionalidades como cupones, tallas especiales o sucursales, o pasamos a diseñar las consultas más importantes?


<img width="727" height="614" alt="image" src="https://github.com/user-attachments/assets/9c661d39-415b-45d0-bb68-0758043e9c14" />
<img width="729" height="612" alt="image" src="https://github.com/user-attachments/assets/ee342eb7-1d00-4097-a3c7-2932525b0a3d" />
<img width="748" height="545" alt="image" src="https://github.com/user-attachments/assets/7272e30d-05ed-414e-b661-d479cccd789b" />
<img width="732" height="534" alt="image" src="https://github.com/user-attachments/assets/4c0ab6e0-82b4-45ea-a11d-9c91a83bfa47" />
<img width="739" height="285" alt="image" src="https://github.com/user-attachments/assets/52c2b0f5-1ec4-44fd-944b-8807694e487d" />


Ahí tienes las 9 entidades con todos sus atributos, tipos de dato y restricciones. Algunos puntos a destacar del diseño:

`UUID` como llave primaria en todas las tablas es preferible a un `INT AUTO_INCREMENT` porque permite generar IDs de forma distribuida sin colisiones, útil si el sistema crece o migra.

`DECIMAL(10,2)` para todos los campos monetarios garantiza precisión exacta sin errores de redondeo, algo crítico en precios y totales. Nunca usar `FLOAT` para dinero.

`precio_unitario` en `DETALLE_PEDIDO` se guarda independiente del precio del producto porque el precio puede cambiar en el futuro y necesitas saber exactamente cuánto se cobró en esa venta.

`ENUM` en campos como `estado` asegura integridad de datos a nivel de base de datos, no solo a nivel de aplicación.

¿Quieres que generemos ahora el script SQL `CREATE TABLE` con todo esto, o pasamos a definir los índices y consultas más importantes?




de a cuerdo a tu respuesta anterior puedes generar un scritp en sql para descargar con el nombre bdzara.sql para las 9 entidades con sus relaciones
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
