meta:
  id: rx2_object_types
  title: Crackdown 2 RX2 Object Types
  application: Crackdown 2
  file-extension: "rx2"
  license: AGPL-3.0-or-later
  endian: be
  encoding: ASCII
  imports:
   - d3d

types:
  raster_object_type:
    seq:
      - id: d3d_base_texture
        type: d3d::d3d_base_texture
      - id: m_type
        type: u1
      - id: face
        type: u1
      - id: num_mip_levels
        type: u1
      - id: locked
        type: u1