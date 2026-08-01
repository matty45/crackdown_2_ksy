  meta:
    id: rx2
    title: Crackdown 2 RX2 Container Format
    application: Crackdown 2
    file-extension: rx2
    license: AGPL-3.0-or-later
    endian: be
    imports:
      - rx2_enums
      - rx2_main_section_types

  doc: |
    RX2 format used by Crackdown 2 (Xbox 360).
    Based on RenderWare 4 (RW4) arena system.

  seq:
    - id: arena
      type: arena

  types:
    magic:
      seq:
        - id: prefix
          size: 4
          contents: [0x89, 0x52, 0x57, 0x34]
        - id: platform
          size: 4
          contents: [0x78, 0x62, 0x32, 0x00]
          doc: The platform the arena file was made for.
        - id: suffix
          size: 4
          contents: [0x0D, 0x0A, 0x1A, 0x0A]

    arena_file_header:
      seq:
        - id: magic
          type: magic
        - id: is_big_endian
          type: b1
        - id: pointer_size_in_bits
          type: u1
        - id: pointer_alignment
          type: u1
        - id: unused
          type: u1
        - id: major_version
          type: u4
        - id: minor_version
          type: u4
        - id: build_no
          type: u4

    arena:
      seq:
        - id: header
          type: arena_file_header
        - id: id
          type: u4
        - id: num_entries
          type: u4
        - id: num_used
          type: u4
        - id: alignment
          type: u4
        - id: virt
          type: u4
          doc: Virtual address base (usually 0)
        - id: dict_start_offset
          type: u4
          doc: "Offset from arena base (this struct start) to dictionary"
        - id: sections_offset
          type: u4
          doc: "Runtime pointer to section manifest (0 in file, set at runtime)"
        - id: section_types_offset
          type: u4
          doc: "Runtime pointer to section types (0 in file, set at runtime)"
        - id: section_external_arenas_offset
          type: u4
          doc: "Runtime unfix context pointer (0 in file)"
        - id: section_subreferences_offset
          type: u4
          doc: "Runtime fixup context pointer (0 in file)"
        - id: unk44
          type: u4
          doc: |
            "Seems to be a direct offset to the 3rd dictentry on most rx2 files 
            (48% of them all), doesnt do that on others."
        - id: base_ptr
          type: u4
          doc: |  
            Runtime self-pointer: set by the game to the in-memory  
            address of this Arena struct itself. Always 0 in the file on disk;  
            populated only after the arena is loaded/initialized at runtime.
        - id: unk4c
          type: u4
          doc: "unknown runtime pointer"
      instances:  
        section_manifest:  
          pos: 0x50  
          type: rx2_main_section_types::arena_section_manifest  

    dict_entry:  
      seq:  
        - id: ptr  
          type: u4  
        - id: reloc  
          type: u4  
        - id: size  
          type: u4  
        - id: align  
          type: u4  
        - id: type_index  
          type: u4  
      instances:  
        resolved_type:  
          value: _root.arena.section_manifest.offsets[0].value.as<rx2_main_section_types::arena_section_types>.type_codes[type_index]  
        body:  
          pos: ptr  
          size: size  
          type:  
            switch-on: resolved_type  
            cases:  
              'rx2_enums::arena_object_type::rwgobjecttype_renderobject': render_object_type  
              
    render_object_type:  
      doc: "Placeholder — real layout of RWGOBJECTTYPE_RENDEROBJECT not yet reverse-engineered"  
      seq:  
        - id: raw  
          size-eos: true

  instances:
    dictionary:
      pos: arena.dict_start_offset
      type: dict_entry
      repeat: expr
      repeat-expr: arena.num_entries
      if: arena.num_entries > 0 and arena.dict_start_offset != 0