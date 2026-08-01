meta:
  id: tpk
  title: Crackdown 2 TPK (Texture pack) file
  application: Crackdown 2
  file-extension: tpk
  license: AGPL-3.0-or-later
  endian: be
  imports:
  - d3d
  
seq:  
  - id: header  
    type: texture_pack_header  
  - id: cached_data  
    type: cached_data  
  - id: physical_data  
    size: header.physical_size  
    doc: |  
      Raw GPU texture data. Each D3DBaseTexture entry in cached_data  
      has its base (and mip) address relocated into this block at  
      runtime.
  
types:  
  texture_pack_header:  
    doc: VFX::TexturePackHeader (12 bytes / 0x0C)  
    seq:  
      - id: num_textures  
        type: u4  
      - id: string_size  
        type: u4  
      - id: physical_size  
        type: u4  
  
  cached_data:  
    seq:  
      - id: name_offsets  
        type: u4  
        repeat: expr  
        repeat-expr: _root.header.num_textures  
        doc: Byte offset from start of string_pool to each texture's name.  
      - id: string_pool  
        size: _root.header.string_size  
        doc: Concatenated null-terminated texture name strings.  
      - id: textures  
        type: d3d::d3d_base_texture  
        repeat: expr  
        repeat-expr: _root.header.num_textures  