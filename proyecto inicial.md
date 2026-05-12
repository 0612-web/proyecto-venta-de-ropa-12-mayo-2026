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


