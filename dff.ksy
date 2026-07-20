meta:
  id: dff
  title: Crackdown 2 DFF file
  application: Crackdown 2
  file-extension: dff
  license: AGPL-3.0-or-later
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
    process: zlib # Remove this for if you are using this ksy with already decompressed files.

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

            _: chunk_body_raw

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

  chunk_body_raw:
    seq:
      - id: data
        size: _parent.header.length

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
      - id: trailing_padding
        type: u8
        doc: Weird padding.

  class_registry_entry:
    seq:
      - id: name
        type: strz
        encoding: UTF-8
      - id: unk_padding
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

enums:
  chunk_type:
    0x71c: class_registry
    0xbadcab01: resource_catalogue