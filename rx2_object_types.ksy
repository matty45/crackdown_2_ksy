meta:
  id: rx2_object_types
  title: Crackdown 2 RX2 typed object payloads
  application: Crackdown 2
  file-extension: rx2
  endian: be
  imports:
    - rx2_enums
    - d3d

doc: |
  Target-specific typed objects recovered from the RX2 corpus and cross-
  validated against FIFALibrary22 RenderWare 4 classes and CD2 IDA exports.

types:
  d3d_resource:
    seq:
      - id: common
        type: u4
      - id: reference_count
        type: u4
      - id: fence
        type: u4
      - id: read_fence
        type: u4
      - id: identifier
        type: u4
      - id: base_flush
        type: u4

  vertex_buffer_object:
    doc: 44-byte VertexBuffer payload; all 17983 corpus instances are 44 bytes.
    seq:
      - id: resource
        type: d3d_resource
      - id: fetch_constant_0
        type: u4
        doc: GPUVERTEX_FETCH_CONSTANT word 0; low 2 bits are type, upper 30 bits encode the Buffer dictionary index.
      - id: fetch_constant_4
        type: u4
        doc: |
          GPUVERTEX_FETCH_CONSTANT word 1. In CD2 the whole word is a size/fetch
          descriptor, not a shared vertex-format identifier. The corpus proves:
          value == 0x10000002 | (alignedByteSize & 0x03FFFFFC), where
          alignedByteSize = (vertex_stride * num_vertices + 31) & ~31.
      - id: vertex_stride
        type: u2
      - id: reserved_22
        type: u2
      - id: num_vertices
        type: u4
      - id: vertex_descriptor_index
        type: u4
        doc: Arena dictionary index of the linked VertexDescriptor.

  index_buffer_object:
    doc: 36-byte IndexBuffer payload; all 47701 corpus instances are 36 bytes.
    seq:
      - id: resource
        type: d3d_resource
      - id: base_address
        type: u4
        doc: Arena dictionary index of the type-0 Buffer blob.
      - id: size_index_buffer
        type: u4
        doc: Equal to (num_indices * 2 + 15) & ~15 for CD2's 16-bit indices.
      - id: num_indices
        type: u4

  raster_object:
    doc: 56-byte Raster payload; all 1839 corpus instances are 56 bytes.
    seq:
      - id: resource
        type: d3d_resource
      - id: mip_flush
        type: u4
      - id: fetch_constant
        type: d3d::gpu_texture_fetch_constant
      - id: m_type
        type: u1
      - id: face
        type: u1
      - id: num_mip_levels
        type: u1
      - id: locked
        type: u1

  vertex_descriptor_element:
    doc: 12-byte CD2 element; first 11 bytes are D3DVERTEXELEMENT9 and byte 11 is the RenderWare ElementType.
    seq:
      - id: stream
        type: u2
      - id: offset
        type: u2
      - id: data_type
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
      - id: type_code
        type: u1

  vertex_descriptor_object:
    doc: |
      CD2 VertexDescriptor is exactly 12 + 12*numElements bytes.
      No extra ElementHash exists in the CD2 payload.
    seq:
      - id: d3d_vertex_declaration
        type: u4
        doc: Usually 0 in standalone descriptors.
      - id: types_flags
        type: u4
      - id: num_elements
        type: u1
      - id: vertex_stride
        type: u1
      - id: num_texture_coordinates
        type: u1
      - id: header_residue
        type: u1
        doc: |
          Authoring-tool residue/padding. It is constant for a given descriptor
          body within an arena, varies across arenas, and is not consumed by the
          declaration cache. Do not assign it a semantic vertex-format meaning.
      - id: elements
        type: vertex_descriptor_element
        repeat: expr
        repeat-expr: num_elements

  mesh_object:
    doc: 24-byte EmbeddedMesh records embedded after CompiledState records in RenderObjects.
    seq:
      - id: instanced_size
        type: u2
        doc: 24 in all corpus meshes.
      - id: num_streams
        type: u2
        doc: 1 in the analyzed corpus.
      - id: num_vertices
        type: u4
      - id: start
        type: u4
      - id: num_indices
        type: u4
      - id: index_buffer_index
        type: u4
      - id: vertex_buffer_index
        type: u4

  compiled_state_object:
    doc: |
      0x0002000B CompiledState. The fixed prefix and the post-slot grammar are
      corpus-backed; the low 20 bits of flags drive 12-byte slots, +0x0C is a
      sampler-slot bitmask, 0x400000 and 0x800000 select two bitfield-splat
      regions, and 0x100000 places an embedded VertexDescriptor at the record end.
      Any unresolved non-first residue is intentionally left raw.
    seq:
      - id: flags
        type: u4
      - id: flags_b
        type: u4
      - id: link
        type: u4
      - id: flags_c
        type: u4
      - id: flags_c_mirror
        type: u4
      - id: state_const
        type: u4
      - id: state_variant
        type: u4
      - id: record_size
        type: u4
      - id: slot_block
        size: record_size - 0x20
    instances:
      sampler_mask:
        value: flags_c
        doc: CompiledState+0x0C sampler-slot bitmask; one tagged texture-reference word is stored per set bit.
      has_embedded_vertex_descriptor:
        value: (flags & 0x00100000) != 0
        doc: The 0x100000 branch ends the record with an embedded 12+12*n VertexDescriptor.
      has_base_splat:
        value: (flags & 0x00400000) != 0
      has_selector_splats:
        value: (flags & 0x00800000) != 0
      has_mesh:
        value: (flags & 0x00200000) != 0
        doc: The 0x200000 bit on CompiledState is followed by the 24-byte EmbeddedMesh.

  skeleton_object:
    doc: |
      Skeleton size = 0x18 + 12*numBones. The three parallel arrays are
      name hashes, bone flags and parent indices.
    seq:
      - id: bone_flags_ptr
        type: u4
      - id: bone_parent_ptr
        type: u4
      - id: bone_name_ptr
        type: u4
      - id: num_name_hashes
        type: u4
      - id: skeleton_id
        type: u4
        doc: |
          FNV-1a-32 over the little-endian uint32 bone-name-hash array. This is
          a content hash of the bone set, not a filename hash or runtime pointer.
      - id: num_bone_flags
        type: u4
      - id: name_hashes
        type: u4
        repeat: expr
        repeat-expr: num_name_hashes
      - id: bone_flags
        type: u4
        repeat: expr
        repeat-expr: num_bone_flags
      - id: num_parent_indices
        type: u4
      - id: parent_indices
        type: s4
        repeat: expr
        repeat-expr: num_parent_indices

  skeleton_sink_group:
    seq:
      - id: draw_group_index
        type: u4
        doc: Arena dictionary index of a RenderObject draw group.
      - id: reserved_04
        type: u4
      - id: reserved_08
        type: u4
      - id: bone_index
        type: u4

  skeleton_sink_object:
    doc: SkeletonSink size = 0x14 + 16*numGroups.
    seq:
      - id: object_id
        type: u4
      - id: update_callback
        type: u4
      - id: groups_ptr
        type: u4
      - id: skeleton_index
        type: u4
      - id: num_groups
        type: u4
      - id: groups
        type: skeleton_sink_group
        repeat: expr
        repeat-expr: num_groups

  render_object_object:
    doc: |
      RenderObject has a 0x70-byte CD2 header followed by a 16-aligned
      CompiledState/Mesh chain. The chain is target-specific and flag-driven.
      The fixed header is exposed; the remainder is preserved verbatim here.
    seq:
      - id: flags
        type: u4
      - id: num_embedded_objects
        type: u4
      - id: end_of_embedded
        type: u4
      - id: field_0c
        type: u4
      - id: field_10
        type: u4
      - id: field_14
        type: u4
      - id: field_18
        type: u4
      - id: field_1c
        type: u4
      - id: field_20
        type: u4
      - id: field_24
        type: u4
      - id: field_28
        type: u4
      - id: field_2c
        type: u4
      - id: field_30
        type: u4
      - id: field_34
        type: u4
      - id: field_38
        type: u4
      - id: field_3c
        type: u4
      - id: field_40
        type: u4
      - id: field_44
        type: u4
      - id: field_48
        type: u4
      - id: field_4c
        type: u4
      - id: field_50
        type: u4
      - id: field_54
        type: u4
      - id: field_58
        type: u4
      - id: field_5c
        type: u4
      - id: field_60
        type: u4
      - id: field_64
        type: u4
      - id: field_68
        type: u4
      - id: embedded_chain
        size-eos: true
        doc: |
          Starts at +0x70. Actual records are 16-aligned and alternate
          CompiledState records and optional 24-byte Mesh records. The exact
          flag-driven slot payload of each CompiledState is parsed separately.
