meta:
  id: rwid_rescatentry
  title: Crackdown 2 Resource Catalog Entry
  application: Crackdown 2
  license: AGPL-3.0-or-later
  endian: le
  
doc: | 
  This represents one entry in the resource catalog TOC that points
  into a .resblock resource.
  
  Notes and usage:
  - `offset` + `res_data_size` specify the slice of the resource payload to
  extract after decompression (if the resource in the .resblock is compressed).

seq:
  - id: name  
    type: str  
    size: 256  
    encoding: UTF-16LE  

  - id: offset
    doc: Offset (u32) into the resource payload referenced by the resblock TOC located inside the DFF.
    type: u4

  - id: res_type
    type: strz
    encoding: ASCII

  - id: res_data_size
    doc: Length in bytes of the resource slice for this catalog entry.
    type: u4
