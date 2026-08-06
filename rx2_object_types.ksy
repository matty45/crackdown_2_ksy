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

  vertex_descriptor_object_type:  
    seq:  
      - id: d3d_vertex_declaration  
        type: u4  
        doc: pointer to D3DVertexDeclaration (raw address, not parsed)  
      - id: registry_cur_be  
        type: u4  
      - id: element_count  
        type: u1  
      - id: m_refcount  
        type: u1  
      - id: m_instancestreams  
        type: u1  
      - id: elements  
        type: vertex_descriptor_element  
        repeat: expr  
        repeat-expr: element_count  
      - id: padding_byte  
        type: u1  
        
  vertex_descriptor_element:  
    seq:  
      - id: stream  
        type: s1  
      - id: field0_be  
        type: s2  
      - id: field1_be  
        type: s2  
      - id: format  
        type: u4  
        enum: rx2_enums::vertex_format 
      - id: field3  
        type: s1  
      - id: field4  
        type: s1  
      - id: field5  
        type: s1