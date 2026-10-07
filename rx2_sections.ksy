meta:
  id: rx2_sections
  title: Crackdown 2 RX2 serialized Arena sections
  application: Crackdown 2
  file-extension: rx2
  endian: be
  imports:
    - rx2_enums

types:
  arena_section:
    doc: Generic 8-byte Arena section header.
    seq:
      - id: type_code
        type: u4
        enum: rx2_enums::arena_object_type
      - id: num_entries
        type: u4

  arena_section_manifest:
    doc: Serialized section manifest at file offset 0x50 in the inspected RX2 family.
    seq:
      - id: type_code
        type: u4
        enum: rx2_enums::arena_object_type
      - id: num_offsets
        type: u4
      - id: pntr_offsets
        type: u4
        doc: Base-relative offset to the section-offset array.
      - id: offsets
        type: section_ptr
        repeat: expr
        repeat-expr: num_offsets
        doc: Section offsets relative to the start of the section manifest at file offset 0x50.

  arena_section_types:
    doc: Per-arena registry mapping dictionary type_index values to full RenderWare type codes.
    seq:
      - id: type_code
        type: u4
        enum: rx2_enums::arena_object_type
      - id: num_type_codes
        type: u4
      - id: offset
        type: u4
        doc: Serialized relative pointer to the type-code array; in the inspected family it is 0x0c.
      - id: type_codes
        type: u4
        enum: rx2_enums::arena_object_type
        repeat: expr
        repeat-expr: num_type_codes

  arena_section_external_arenas:
    doc: External-arena section. The first three post-header words are runtime pointer slots; the trailing words are arena IDs.
    seq:
      - id: type_code
        type: u4
        enum: rx2_enums::arena_object_type
      - id: num_external_arena_ids
        type: u4
      - id: dict_ptr
        type: u4
        doc: Base-relative offset to the external-arena dictionary array.
      - id: runtime_arena_ptr
        type: u4
        doc: Runtime-only pointer slot; serialized value is not a file offset.
      - id: runtime_manager_ptr
        type: u4
        doc: Runtime-only pointer slot; serialized value is not a file offset.
      - id: runtime_arena_ptr_2
        type: u4
        doc: Runtime-only pointer slot; serialized value is not a file offset.
      - id: external_arena_ids
        type: u4
        repeat: expr
        repeat-expr: num_external_arena_ids
        doc: Raw external arena IDs.

  arena_section_subreferences_record:
    seq:
      - id: object_id
        type: u4
      - id: offset
        type: u4

  arena_section_subreferences:
    seq:
      - id: type_code
        type: u4
        enum: rx2_enums::arena_object_type
      - id: num_entries
        type: u4
      - id: num_subrefs
        type: u4
      - id: dict_ptr
        type: u4
        doc: Runtime/fixup pointer; inspected files commonly store 0.

  section_ptr:
    seq:
      - id: ofs
        type: u4
    instances:
      header:
        pos: 0x50 + ofs
        type: arena_section
      value:
        pos: 0x50 + ofs
        type:
          switch-on: header.type_code
          cases:
            'rx2_enums::arena_object_type::rwobjecttype_sectiontypes': arena_section_types
            'rx2_enums::arena_object_type::rwobjecttype_sectionexternalarenas': arena_section_external_arenas
            'rx2_enums::arena_object_type::rwobjecttype_sectionsubreferences': arena_section_subreferences
            _: arena_section
