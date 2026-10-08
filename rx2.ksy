meta:
  id: rx2
  title: Crackdown 2 RX2 / RenderWare 4 Arena
  application: Crackdown 2
  file-extension: rx2
  endian: be
  imports:
    - rx2_enums
    - rx2_sections
    - rx2_object_types

seq:
  - id: header
    type: arena_file_header

  - id: arena_id
    type: u4
    doc: |
      Arena id/handle. In CD2 this is an LCG-minted runtime handle, not a
      content/name hash.

  - id: num_entries
    type: u4
    doc: Number of serialized dictionary entries.

  - id: num_dictionary
    type: u4
    doc: Dictionary entry count. Equal to num_entries in the analyzed corpus.

  - id: alignment
    type: u4
    doc: Arena alignment. Corpus values are 0x10 or 0x1000.

  - id: virt
    type: u4
    doc: Virtual arena field; observed as zero in the analyzed RX2 corpus.

  - id: dict_offset
    type: u4
    doc: File-relative offset of the serialized 20-byte object dictionary.

  - id: section_manifest_ptr
    type: u4
    doc: Stale host pointer / serialized arena pointer; do not treat as a file offset.

  - id: section_types_ptr
    type: u4
    doc: Stale host pointer / serialized arena pointer; do not treat as a file offset.

  - id: section_external_arenas_ptr
    type: u4
    doc: Stale host pointer / serialized arena pointer; do not treat as a file offset.

  - id: section_subreferences_ptr
    type: u4
    doc: Stale host pointer / serialized arena pointer; do not treat as a file offset.

  - id: section_virtual_size
    type: u4
    doc: |
      Virtual manifest/sections size. Corpus relationship:
      172 + 36 + 8*numTypes + 16*numExternalArenas.

  - id: reserved_48
    type: u4
    doc: Reserved; observed zero.

  - id: reserved_4c
    type: u4
    doc: Reserved; observed zero.

  - id: section_manifest
    type: rx2_sections::arena_section_manifest
    doc: Section manifest begins at file offset 0x50.

instances:
  section_types:
    pos: 0x50 + section_manifest.offsets[0].ofs
    type: rx2_sections::arena_section_types
    doc: First manifest section is SectionTypes in the analyzed CD2 family.

  dictionary:
    pos: dict_offset
    type: dict_entry
    repeat: expr
    repeat-expr: num_dictionary
    if: num_dictionary > 0

  trailing:
    pos: dict_offset + num_dictionary * 20
    size-eos: true
    if: dict_offset + num_dictionary * 20 < _io.size
    doc: |
      Remaining bytes after the dictionary. This region contains the compiled/GPU
      command-buffer structures documented by the corpus audit. The package keeps
      any still-unresolved subregions raw rather than assigning invented semantics.

types:
  arena_file_header:
    seq:
      - id: magic
        type: magic

      - id: is_big_endian
        type: u1
        valid: 1

      - id: pointer_size_in_bits
        type: u1
        valid: 0x20

      - id: pointer_alignment
        type: u1
        valid: 4

      - id: unused
        type: u1

      - id: major_version
        type: u4

      - id: minor_version
        type: u4

      - id: build_no
        type: u4

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

  dict_entry:
    seq:
      - id: file_offset
        type: u4
        doc: File offset of the object payload.

      - id: reloc
        type: u4
        doc: Stale authoring-process pointer/relocation value; ignored by the CD2 file parser.

      - id: size
        type: u4

      - id: align
        type: u4
        doc: Object alignment. Corpus values are non-zero powers of two.

      - id: type_index
        type: u4
        doc: Per-arena SectionTypes index.

    instances:
      resolved_type:
        value: _root.section_types.type_codes[type_index]
        doc: Full RenderWare object type code.

      body:
        pos: file_offset
        size: size
        type:
          switch-on: resolved_type
          cases:
            'rx2_enums::arena_object_type::unknown': buffer_object
            'rx2_enums::arena_object_type::rwgobjecttype_raster': rx2_object_types::raster_object
            'rx2_enums::arena_object_type::rwgobjecttype_vdes': rx2_object_types::vertex_descriptor_object
            'rx2_enums::arena_object_type::rwgobjecttype_vbuf': rx2_object_types::vertex_buffer_object
            'rx2_enums::arena_object_type::rwgobjecttype_ibuf': rx2_object_types::index_buffer_object
            'rx2_enums::arena_object_type::rwgobjecttype_mesh': rx2_object_types::mesh_object
            'rx2_enums::arena_object_type::rwgobjecttype_compiledstate': rx2_object_types::compiled_state_object
            'rx2_enums::arena_object_type::rwgobjecttype_renderobject': rx2_object_types::render_object_object
            'rx2_enums::arena_object_type::objecttype_keyframeanim': raw_payload
            'rx2_enums::arena_object_type::objecttype_skeleton': rx2_object_types::skeleton_object
            'rx2_enums::arena_object_type::objecttype_skeletonsink': rx2_object_types::skeleton_sink_object
            'rx2_enums::arena_object_type::objecttype_c2_vehicle_component': rx2_object_types::c2_vehicle_component
            _: raw_payload

  buffer_object:
    seq:
      - id: data
        size-eos: true
        doc: |
          Type-index 0 Buffer payload. In CD2 these are the raw vertex/index/
          texture blobs referenced by VertexBuffer, IndexBuffer and Raster.

  raw_payload:
    seq:
      - id: data
        size-eos: true
