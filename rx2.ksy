  meta:
    id: rx2
    title: Crackdown 2 RX2 Container Format
    application: Crackdown 2
    file-extension: rx2
    license: AGPL-3.0-or-later
    endian: be

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
          type: arena_section_manifest  
          
    arena_section:
      doc: "Base class for all arena sections"
      seq:
        - id: type_code
          type: u4  
          enum: arena_object_type
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
          enum: arena_object_type  
        - id: num_entries  
          type: u4  
        - id: reserved_1
          type: u4  
          doc: "Runtime-only cache pointer"  
        - id: reserved_2 
          type: u4  
          doc: "Runtime-only cache pointer"  
          
    arena_section_external_arenas:  
      doc: "External arena references"  
      seq:  
        - id: type_code  
          type: u4  
          enum: arena_object_type  
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
          enum: arena_object_type
          doc: "Should be RWOBJECTTYPE_SECTIONTYPES (0x10005)"
        - id: num_entries
          type: u4
          doc: "Number of type codes"
        - id: offset
          type: u4
          doc: "Offset to type codes array (usually 12)"
        - id: type_codes
          type: u4  
          enum: arena_object_type
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
              'arena_object_type::rwobjecttype_sectiontypes': arena_section_types
              'arena_object_type::rwobjecttype_sectionexternalarenas': arena_section_external_arenas
              'arena_object_type::rwobjecttype_sectionsubreferences': arena_section_subreferences  
              _: arena_section

          
    arena_section_manifest:  
      seq:  
        - id: type_code  
          type: u4  
          enum: arena_object_type  
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

    dict_entry:  
      doc: "20-byte table-of-contents entry (stride = 0x14)"  
      seq:  
        - id: ptr  
          type: u4  
          doc: "File offset to object data (fixed up to absolute address at runtime)"  
        - id: reloc  
          type: u4  
          doc: "Saved copy of ptr, written during fixup (runtime use only)"  
        - id: size  
          type: u4  
          doc: "Size of object data in bytes"  
        - id: align  
          type: u4  
          doc: "Alignment of object data"  
        - id: type_index  
          type: u4  
      instances:  
        body:  
          pos: ptr  
          size: size  
          valid:  
            expr: ptr + size <= _root._io.size
          doc: "Raw object data"

  instances:
    dictionary:
      pos: arena.dict_start_offset
      type: dict_entry
      repeat: expr
      repeat-expr: arena.num_entries
      if: arena.num_entries > 0 and arena.dict_start_offset != 0

  enums:  
    arena_object_type:  
      0x00010000: rwobjecttype_na  
      0x00010001: rwobjecttype_arena  
      0x00010002: rwobjecttype_raw  
      0x00010003: rwobjecttype_subreference  
      0x00010004: rwobjecttype_sectionmanifest  
      0x00010005: rwobjecttype_sectiontypes  
      0x00010006: rwobjecttype_sectionexternalarenas  
      0x00010007: rwobjecttype_sectionsubreferences  
      0x00010008: rwobjecttype_sectionatoms  
      0x00010009: rwobjecttype_defarenaimports  
      0x0001000a: rwobjecttype_defarenaexports  
      0x0001000b: rwobjecttype_defarenatypes  
      0x0001000c: rwobjecttype_defarenadefinedarenaid  
      0x0001000d: rwobjecttype_attributepacket  
      0x0001000e: rwobjecttype_attributepacket_delegate  
      0x0001000f: rwobjecttype_bittable  
      0x00010010: rwobjecttype_arenalocalatomtable  
      0x00010030: rwobjecttype_baseresource_start  
      0x00010031: rwobjecttype_baseresource_1  
      0x00010032: rwobjecttype_baseresource_2  
      0x00010033: rwobjecttype_baseresource_3  
      0x00010034: rwobjecttype_baseresource_4  
      0x00010035: rwobjecttype_baseresource_5  
      0x00010036: rwobjecttype_baseresource_6  
      0x00010037: rwobjecttype_baseresource_7  
      0x00010038: rwobjecttype_baseresource_8  
      0x00010039: rwobjecttype_baseresource_9  
      0x0001003a: rwobjecttype_baseresource_a  
      0x0001003b: rwobjecttype_baseresource_b  
      0x0001003c: rwobjecttype_baseresource_c  
      0x0001003d: rwobjecttype_baseresource_d  
      0x0001003e: rwobjecttype_baseresource_e  
      0x0001003f: rwobjecttype_baseresource_reservedto  
      0x00020000: rwgobjecttype_na  
      0x00020001: rwgobjecttype_camera  
      0x00020002: rwgobjecttype_palette  
      0x00020003: rwgobjecttype_raster  
      0x00020004: rwgobjecttype_vdes  
      0x00020005: rwgobjecttype_vbuf  
      0x00020006: rwgobjecttype_ides  
      0x00020007: rwgobjecttype_ibuf  
      0x00020008: rwgobjecttype_light  
      0x00020009: rwgobjecttype_mesh  
      0x0002000a: rwgobjecttype_shader  
      0x0002000b: rwgobjecttype_compiledstate  
      0x0002000c: rwgobjecttype_renderobject  
      0x0002000d: rwgobjecttype_gsdata  
      0x0002000e: rwgobjecttype_vertexshader  
      0x0002000f: rwgobjecttype_vertexdata  
      0x00020010: rwgobjecttype_indexdata  
      0x00020011: rwgobjecttype_rasterdata  
      0x00020012: rwgobjecttype_buildstate  
      0x00020013: rwgobjecttype_pixelshader  
      0x00020015: rwgobjecttype_profilemesh  
      0x00020016: rwgobjecttype_designviewobject  
      0x00020017: rwgobjecttype_profilerenderobject  
      0x00020018: rwgobjecttype_image  
      0x00020019: rwgobjecttype_renderobjectcontainer  
      0x0002001a: rwgobjecttype_meshcompiledstatelink  
      0x0002001b: rwgobjecttype_shadercode  
      0x00020020: rwgobjecttype_font  
      0x00020021: rwgobjecttype_glyphtable  
      0x00020022: rwgobjecttype_kerntable  
      0x00020023: rwgobjecttype_pagetable  
      0x00020024: rwgobjecttype_rastertexture  
      0x00020025: rwgobjecttype_facename  
      0x0002007f: rwgobjecttype_updatelocator  
      0x00020081: rwgobjecttype_meshhelper  
      0x000200e0: rwgobjecttype_na2  
      0x000200e1: rwgobjecttype_viewportparameters  
      0x000200e2: rwgobjecttype_scissorrectparameters  
      0x000200e3: rwgobjecttype_clearcolorparameters  
      0x000200e4: rwgobjecttype_cleardepthstencilparameters  
      0x000200e5: rwgobjecttype_drawindexedparameters  
      0x000200e6: rwgobjecttype_drawparameters  
      0x000200e7: rwgobjecttype_pixelbuffer  
      0x000200e8: rwgobjecttype_texture  
      0x000200e9: rwgobjecttype_vertexdescriptor  
      0x000200ea: rwgobjecttype_vertexbuffer  
      0x000200eb: rwgobjecttype_indexbuffer  
      0x000200ec: rwgobjecttype_programbuffer  
      0x000200ed: rwgobjecttype_statebuffer  
      0x000200ee: rwgobjecttype_programstatebuffer  
      0x000200ef: rwgobjecttype_programstates  
      0x000200f1: rwgobjecttype_samplerstate  
      0x000200f3: rwgobjecttype_rendertargetstate  
      0x000200f4: rwgobjecttype_blendstate  
      0x000200f5: rwgobjecttype_depthstencilstate  
      0x000200f6: rwgobjecttype_rasterizerstate  
      0x000200f7: rwgobjecttype_vertexprogramstate  
      0x000200f8: rwgobjecttype_programstatehandle  
      0x000200f9: rwgobjecttype_drawinstancedparameters  
      0x000200fa: rwgobjecttype_drawindexedinstancedparameters  
      0x00040000: objecttype_na1  
      0x00040001: objecttype_part  
      0x00040002: objecttype_partdefinition  
      0x00040003: objecttype_jointedpair  
      0x00040004: objecttype_jointlimit  
      0x00040005: objecttype_jointskeleton  
      0x00040006: objecttype_assembly  
      0x00040007: objecttype_assemblydefinition  
      0x00070000: objecttype_na2  
      0x00070001: objecttype_keyframeanim  
      0x00070002: objecttype_skeleton  
      0x00070003: objecttype_animationskin  
      0x00070004: objecttype_interpolator  
      0x00070005: objecttype_featherinterpolator  
      0x00070006: objecttype_oneboneik  
      0x00070007: objecttype_twoboneik  
      0x00070008: objecttype_blender  
      0x00070009: objecttype_weightedblender  
      0x0007000a: objecttype_remapper  
      0x0007000b: objecttype_skeletonsink  
      0x0007000c: objecttype_skinsink  
      0x0007000d: objecttype_lightsink  
      0x0007000e: objecttype_camerasink  
      0x0007000f: objecttype_skinmatrixbuffer  
      0x00070010: objecttype_tweakcontroller  
      0x00070011: objecttype_shadersink  
      0x00080000: rwcobjecttype_na  
      0x00080001: rwcobjecttype_volume  
      0x00080002: rwcobjecttype_simplemappedarray  
      0x00080003: rwcobjecttype_trianglekdtreeprocedural  
      0x00080004: rwcobjecttype_kdtreemappedarray  
      0x00080005: rwcobjecttype_bbox  
      0x00080006: rwcobjecttype_clusteredmesh  
      0x00eb0000: rwobjecttype_rendermeshdata  
      0x00eb0001: rwobjecttype_rendermodeldata  
      0x00eb0003: rwobjecttype_simpletrimeshdata  
      0x00eb0004: rwobjecttype_splinedata  
      0x00eb0005: rwobjecttype_rendermaterialdata  
      0x00eb0006: rwobjecttype_collisionmaterialdata  
      0x00eb0007: rwobjecttype_rollerdescdata  
      0x00eb0008: rwobjecttype_versiondata  
      0x00eb0009: rwobjecttype_locationdescdata  
      0x00eb000a: rwobjecttype_collisionmodeldata  
      0x00eb000b: rwobjecttype_tableofcontents  
      0x00eb000c: rwobjecttype_collisionbezierdata  
      0x00eb000d: rwobjecttype_instancedata  
      0x00eb000e: rwobjecttype_renderblendshapeedata  
      0x00eb000f: rwobjecttype_worldpainterlayerdata  
      0x00eb0010: rwobjecttype_worldpainterquadtreedata  
      0x00eb0011: rwobjecttype_worldpainterdictionarydata  
      0x00eb0012: rwobjecttype_navmeshdata  
      0x00eb0013: rwobjecttype_raindata  
      0x00eb0014: rwobjecttype_aipathdata  
      0x00eb0015: rwobjecttype_statsdata  
      0x00eb0016: rwobjecttype_massivedata  
      0x00eb0017: rwobjecttype_depthmapdata  
      0x00eb0018: rwobjecttype_liondata  
      0x00eb0019: rwobjecttype_triggerinstancedata  
      0x00eb001a: rwobjecttype_waypointdata  
      0x00eb001b: rwobjecttype_embeddeddata  
      0x00eb001c: rwobjecttype_emitterwaypointdata  
      0x00eb001d: rwobjecttype_dmodata  
      0x00eb001e: rwobjecttype_hotpointdata  
      0x00eb001f: rwobjecttype_grabdata  
      0x00eb0020: rwobjecttype_spatialmap  
      0x00eb0021: rwobjecttype_visualindicatordata  
      0x00eb0022: rwobjecttype_navmesh2data  
      0x00eb0023: rwobjecttype_renderoptimeshdata  
      0x00eb0024: rwobjecttype_irradiancedata  
      0x00eb0025: rwobjecttype_antifrustumdata  
      0x00eb0064: rwobjecttype_splinesubref  
      0x00eb0065: rwobjecttype_rollerdescsubref  
      0x00eb0066: rwobjecttype_rendermaterialsubref  
      0x00eb0067: rwobjecttype_collisionmaterialsubref  
      0x00eb0068: rwobjecttype_locationdescsubref  
      0x00eb0069: rwobjecttype_instancesubref  
      0x00eb006a: rwobjecttype_waypointsubref  
      0x00eb006b: rwobjecttype_triggerinstancesubref  
      0x00eb006c: rwobjecttype_emitterwaypointsubref  
      0x00eb006d: rwobjecttype_dmosubref  
      0x00eb006e: rwobjecttype_hotpointsubref  
      0x00eb006f: rwobjecttype_grabsubref  
      0x00eb0070: rwobjecttype_visualindicatorsubref  
      0x00ec0010: arenadictionary  
      0x7fffffff: forcenumsizeint