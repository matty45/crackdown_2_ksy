meta:
  id: dff
  title: Crackdown 2 DFF file
  application: Crackdown 2
  file-extension: dff
  license: AGPL-3.0-or-later
  ks-version: 0.9
  endian: le

doc: |
  This file format is used to store both
  game assets and metadata that is used by the game or its editor.

  A dff file is sometimes? or always accompanied by a .resblock file
  which stores large assets that for some
  reason cannot fit into the dff itself.

seq:
  - id: rw_stream
    size-eos: true
    type: rw_compressed_file_stream
    process: zlib # Remove this if you are using this ksy with already decompressed files.

types:
  rw_compressed_file_stream:
    seq:
      - id: chunks
        type: chunk
        repeat: eos
  chunk:
    seq:
      - id: header
        type: chunk_header
      - id: body
        type:
          switch-on: header.type
          cases:
            'chunk_type::class_registry': class_registry
            'chunk_type::resource_catalogue': resource_catalogue
            'chunk_type::resource_cache_global': res_cache_global
            'chunk_type::resource_cache_level': res_cache_level
            'chunk_type::embedded_asset': embedded_asset
            'chunk_type::entity': entity

  chunk_header:
    doc: 12-byte on-disk chunk header.
    seq:
      - id: type
        type: u4
        enum: chunk_type
      - id: length
        type: u4
      - id: version
        type: u4
        doc: Packed version + build number

  class_registry:
    doc: |
      A chunk containing a list of classes that the dff uses.
      Not read or used by the game itself, so it must be editor related.
    seq:
      - id: num_entries
        type: u4
      - id: entries
        type: class_registry_entry
        repeat: expr
        repeat-expr: num_entries
      - id: reserved
        type: u8
        doc: Reserved padding.

  class_registry_entry:
    seq:
      - id: name
        type: strz
        encoding: UTF-8
      - id: reserved
        size: (4 - ((name.length + 1) % 4)) % 4
      - id: instance_count
        type: u4
        doc: Number of instances of this class exported.

  resource_catalogue:
    doc: |
      Resource catalog chunks contain a table of contents to be used with
      the dff files corresponding .resblock file.
      This chunk has a malformed length in its chunk header in the official
      dff files that crackdown 2 uses. So the size is grabbed dynamically
      instead.
    seq:
      - id: file_name_length
        type: u4
      - id: file_name
        size: file_name_length
        type: str
        encoding: UTF-16LE
      - id: num_entries
        type: u4
      - id: entries
        type: resource_catalogue_entry
        repeat: expr
        repeat-expr: num_entries

  resource_catalogue_entry:
    seq:
      - id: name
        size: 0x100
        type: str
        encoding: UTF-16LE
      - id: block_type
        size: 0x40
        type: str
        encoding: UTF-16LE
      - id: ofs_resource
        type: u8
      - id: len_resource
        type: u4
      - id: compressed_size
        type: u4
      - id: actual_compressed_size
        type: u4
      - id: checksum
        type: u4

  res_cache_global:
    doc: Global resource cache.
    seq:
      - id: num_entries
        type: u4
      - id: entries
        type: res_cache_global_entry
        repeat: expr
        repeat-expr: num_entries

  res_cache_global_entry:
    seq:
      - id: block_size
        type: u4
      - id: type
        size: 0x40
        type: str
        encoding: UTF-16LE
        doc: wchar16 type[32].

  res_cache_level:
    doc: Level resource cache.
    seq:
      - id: num_entries
        type: u4
      - id: entries
        type: res_cache_level_entry
        repeat: expr
        repeat-expr: num_entries

  res_cache_level_entry:
    seq:
      - id: type
        size: 0x40
        type: str
        encoding: UTF-16LE
        doc: wchar16 type[32].
      - id: block_size
        type: u4
      - id: num_configs
        type: u4
      - id: configs
        type: res_cache_config
        repeat: expr
        repeat-expr: num_configs

  res_cache_config:
    seq:
      - id: name
        size: 0x40
        type: str
        encoding: UTF-16LE
        doc: wchar16 cfgName[32].
      - id: num_blocks
        type: u4

  embedded_asset:
    doc: |
      A game file/asset fully located inside of the dff.
    seq:
      - id: len_header
        type: u4
      - id: header
        size: len_header
        type: embedded_asset_header
      - id: len_data
        type: u4
      - id: data
        size: len_data
        doc: Nested RenderWare stream payload.

  embedded_asset_header:
    seq:
      - id: name_len
        type: u4
      - id: name
        size: name_len
        type: str
        encoding: ASCII
      - id: guid
        size: 16
        type: guid
      - id: type_len
        type: u4
      - id: type
        size: type_len
        type: str
        encoding: ASCII
      - id: str2_len
        type: u4
      - id: str2
        size: str2_len
        type: str
        encoding: ASCII
      - id: extra
        size-eos: true
        doc: Remaining param bytes (u32 extra and any trailing padding).

  entity:
    doc: |
      This chunk is used to tell the game engine to place/create an entity with specified attributes.
      What class to spawn, should it be spawned in this build of the game,
      what class specific attributes have been set for it, etc.
    seq:
      - id: pad
        type: u4
      - id: data_config_mask_lo
        type: u4
      - id: data_config_mask_hi
        type: u4
      - id: packet
        size: _parent.header.length - 12
        type: attribute_packet
    instances:
      data_config_mask:
        value: data_config_mask_hi * 0x100000000 + data_config_mask_lo
        doc: |
          I believe this is used by the engine to selectively ignore certain entities
          to create depending on the engines build type. (debug, release, etc)

  attribute_packet:
    seq:
      - id: entries
        type: packet_entry
        repeat: eos

  packet_entry:
    seq:
      - id: size
        type: u4
        doc: Total size of this record (header + data), 0 terminates chain.
      - id: type
        type: u4
        enum: packet_entry_type
      - id: data
        size: size - 8
        type:
          switch-on: type
          cases:
            'packet_entry_type::instance_guid': guid
            'packet_entry_type::class_name': packet_str # The class of the entity to spawn.
            'packet_entry_type::attribute_section': packet_str # What will handle the settings/attributes for this class.
        if: size != 0

  packet_str:
    seq:
      - id: value
        type: strz
        encoding: ASCII

  guid:
    doc: 16 byte guid
    seq:
      - id: data1
        type: u4
      - id: data2
        type: u2
      - id: data3
        type: u2
      - id: data4
        type: u1
      - id: data5
        type: u1
      - id: data6
        type: u1
        repeat: expr
        repeat-expr: 6
enums:
  chunk_type:
    0x704: entity
    0x716: embedded_asset
    0x71c: class_registry
    0xbadcab01: resource_catalogue
    0xbadcab02: resource_cache_global
    0xbadcab03: resource_cache_level

  packet_entry_type:
    0x20000000: class_name
    0x40000000: instance_guid
    0x80000000: attribute_section
