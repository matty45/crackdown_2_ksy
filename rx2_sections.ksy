meta:
  id: rx2_sections
  title: Crackdown 2 RX2 Sections
  application: Crackdown 2
  file-extension: "rx2"
  license: AGPL-3.0-or-later
  endian: be
  encoding: ASCII
  imports:
    - rx2_enums

types:
  arena_section:
    doc: "Base class for all arena sections"
    seq:
      - id: type_code
        type: u4  
        enum: rx2_enums::arena_object_type
        doc: "Section type code"
      - id: num_entries
        type: u4
        doc: "Number of entries in this section"

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
        doc: "Runtime-only pointer"  
        
  arena_section_external_arenas:  
    doc: "External arena references"  
    seq:  
      - id: type_code  
        type: u4  
        enum: rx2_enums::arena_object_type  
        doc: "Should be RWOBJECTTYPE_SECTIONEXTERNALARENAS (0x10006)"  
      - id: num_entries  
        type: u4  
      - id: dict_ptr  
        type: u4  
        doc: |  
          Base-relative offset to the dict[] array (same rebasing pattern  
          as arena_section_manifest.dict_ptr: dict += obj at fixup time).  
      - id: reserved_c  
        type: u4  
        doc: |  
          Runtime-only: overwritten with iterator->m_arena (self-arena  
          pointer) during ArenaSectionExternalArenas::Fixup. Expected 0 on disk.  
      - id: reserved_10  
        type: u4  
        doc: |  
          Runtime-only: overwritten with an ArenaManager::Data()-derived  
          pointer during Fixup. Expected 0 on disk.  
      - id: reserved_14  
        type: u4  
        doc: |  
          Runtime-only: overwritten with iterator->m_arena again during  
          Fixup. Expected 0 on disk. (Fixup only touches indices 0-2 of  
          dict[] unconditionally; entries below are only populated when  
          num_entries > 3.)  
      - id: external_arena_ids  
        type: u4  
        repeat: expr  
        repeat-expr: num_entries  
        doc: |  
          Raw IDs of externally-referenced arenas. Resolved into live  
          Arena* pointers at fixup time via a hash lookup  
          (HashContainer<...ArenaIdMapHashTraits>::FindIndexForKey)  
          against the global loaded-arena table, not stored as offsets/pointers on disk.
    instances:
      dictionary_ptrs:
        pos: _parent.ofs + 0x50 + dict_ptr
        type: u4
        repeat: expr
        repeat-expr: num_entries
        if: num_entries > 0 and dict_ptr != 0  
        
      
  arena_section_types:
    doc: "Section type codes registry"
    seq:
      - id: type_code
        type: u4  
        enum: rx2_enums::arena_object_type
        doc: "Should be RWOBJECTTYPE_SECTIONTYPES (0x10005)"
      - id: num_entries
        type: u4
        doc: "Number of type codes"
      - id: offset
        type: u4
        doc: "Offset to type codes array (usually 12)"
      - id: type_codes
        type: u4  
        enum: rx2_enums::arena_object_type
        repeat: expr
        repeat-expr: num_entries
      

  section_ptr:  
    seq:  
      - id: ofs  
        type: u4  
    instances:  
      header:  
        pos: ofs + 0x50  
        type: arena_section  
        doc: "Peek at the generic {type_code, num_entries} header to determine the real type"  
      value:  
        pos: ofs + 0x50  
        type:  
          switch-on: header.type_code  
          cases:  
            'rx2_enums::arena_object_type::rwobjecttype_sectiontypes': arena_section_types
            'rx2_enums::arena_object_type::rwobjecttype_sectionexternalarenas': arena_section_external_arenas
            'rx2_enums::arena_object_type::rwobjecttype_sectionsubreferences': arena_section_subreferences  
            _: arena_section

        
  arena_section_manifest:  
    seq:  
      - id: type_code  
        type: u4  
        enum: rx2_enums::arena_object_type  
      - id: num_entries  
        type: u4  
      - id: pntr_offsets  
        type: u4  
        doc: On-disk, base-relative offset to the offsets array (rebased at runtime).  
      - id: offsets  
        type: section_ptr  
        repeat: expr  
        repeat-expr: num_entries  
        doc: |  
          Each element's absolute section location is offsets[i].value,  
          computed as ofs + 0x50 (base of arena_section_manifest).  