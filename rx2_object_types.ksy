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
      - id: unk1  
        type: u4  
      - id: element_count  
        type: u1  
      - id: unk2  
        type: u1  
      - id: unk3  
        type: u1  
      - id: elements  
        type: vertex_descriptor_element  
        repeat: expr  
        repeat-expr: element_count  
      - id: unk4  
        type: u1  
        
  vertex_descriptor_element:
    seq:
      - id: unk
        type: u1
      - id: stream
        type: u2
        doc: "D3D Stream index + Xenos flags (0x200=VTF, 0x100=Instancing)"
      - id: offset
        type: u2
      - id: format
        type: u4
        enum: d3d::d3ddecltype
      - id: method
        type: u1
        enum: d3d::d3ddeclmethod
      - id: usage
        type: u1
        enum: d3d::d3ddeclusage
      - id: usage_index
        type: u1