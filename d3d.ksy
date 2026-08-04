meta:  
  id: d3d  
  title: Crackdown 2 D3D related types  
  application: Crackdown 2  
  license: AGPL-3.0-or-later  
  endian: be  
  
types:  
  d3d_base_texture:  
    doc: |  
      Xbox 360 D3DBaseTexture (52 bytes / 0x34).  
      Inherits D3DResource (24 bytes / 0x18: Common..BaseFlush),  
      then adds MipFlush and the 24-byte GPUTEXTURE_FETCH_CONSTANT.  
      XGOffsetBaseTextureAddress patches format.base_address (word1 bits[31:12])  
      and format.mip_address (word5 bits[31:12]) at load time to point into  
      physical_data. Mip address is only patched when format.max_mip_level > 0.  
    seq:  
      - id: common  
        type: u4  
        doc: |  
          Bits [3:0] = D3DRESOURCETYPE (3 = texture).  
          Bit  [30]  = set for D3DRTYPE_VOLUME (with additional checks).  
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
      - id: mip_flush  
        type: u4  
      - id: format  
        type: gpu_texture_fetch_constant  
  
  gpu_texture_fetch_constant:  
    doc: |  
      Xbox 360 GPUTEXTURE_FETCH_CONSTANT (24 bytes / 0x18 = 6 DWORDs).  
      Bitfields are listed MSB-first within each 32-bit word (big-endian).  
      BitPos comments reflect the LSB-origin values from the PDB definition.  
    seq:  
      # ── word0 (offset 0x00) ──────────────────────────────────────────  
      - id: tiled  
        type: b1  
        doc: "BitPos=31. Surface is GPU-tiled."  
      - id: pitch  
        type: b9  
        doc: "BitPos=22. Surface pitch in tiles, minus 1."  
      - id: reserved0  
        type: b3  
        doc: "BitPos=19. Reserved (3 bits)."  
      - id: clamp_z  
        type: b3  
        enum: gpuclamp  
        doc: "BitPos=16. Wrap/clamp mode for W axis (GPUCLAMP)."  
      - id: clamp_y  
        type: b3  
        enum: gpuclamp  
        doc: "BitPos=13. Wrap/clamp mode for V axis (GPUCLAMP)."  
      - id: clamp_x  
        type: b3  
        enum: gpuclamp  
        doc: "BitPos=10. Wrap/clamp mode for U axis (GPUCLAMP)."  
      - id: sign_w  
        type: b2  
        enum: gpusign  
        doc: "BitPos=8. Component sign for W (GPUSIGN)."  
      - id: sign_z  
        type: b2  
        enum: gpusign  
        doc: "BitPos=6. Component sign for Z (GPUSIGN)."  
      - id: sign_y  
        type: b2  
        enum: gpusign  
        doc: "BitPos=4. Component sign for Y (GPUSIGN)."  
      - id: sign_x  
        type: b2  
        enum: gpusign
        doc: "BitPos=2. Component sign for X (GPUSIGN)."  
      - id: type  
        type: b2  
        enum: gpuconstanttype
        doc: "BitPos=0. Fetch constant type (GPUFETCHCONSTANT_TYPE; 2 = texture)."  
      # ── word1 (offset 0x04) ──────────────────────────────────────────  
      - id: base_address  
        type: b20  
        doc: |  
          BitPos=12. Physical surface address >> 12.  
          Patched unconditionally by XGOffsetBaseTextureAddress:  
              word1 = (word1 & 0xFFF) | (pBaseAddress + (word1 & 0xFFFFF000)) & 0xFFFFF000  
          Zero in the file before relocation.  
          Also accessible as D3DResource pThis[1].Fence (offset 0x20 from  
          D3DBaseTexture base), where bit 10 = Stacked (array texture flag).  
      - id: clamp_policy  
        type: b1  
        doc: "BitPos=11. Clamp policy (0 = D3D, 1 = OGL)."  
      - id: stacked  
        type: b1  
        doc: |  
          BitPos=10. Stacked (array) texture flag.  
          Checked by D3DResource_GetType as (pThis[1].Fence & 0x400) to  
          distinguish D3DRTYPE_ARRAYTEXTURE from D3DRTYPE_TEXTURE.  
      - id: request_size  
        type: b2  
        doc: "BitPos=8. Memory request size hint (GPUREQUESTSIZE). GPUREQUESTSIZE_256BIT = 0	GPUREQUESTSIZE_512BIT	= 1"  
      - id: endian  
        type: b2  
        enum: gpuendian  
        doc: "BitPos=6. Endian swap mode (GPUENDIAN)."  
      - id: data_format  
        type: b6  
        enum: gpu_texture_format  
        doc: "BitPos=0. Texel format (GPUTEXTUREFORMAT / D3DFORMAT encoding)."  
      # ── word2 (offset 0x08) ──────────────────────────────────────────  
      - id: size  
        type: gpu_texture_size  
        size: 4  
        doc: |  
          GPUTEXTURESIZE union. Which variant applies is determined by  
          the dimension field (word5 BitPos=9):  
              0 = 1D  → size.as_1d  
              1 = 2D  → size.as_2d  
              2 = 3D  → size.as_3d  
              3 = cube/stack → size.as_stack  
          All dimension values are stored as (actual_size - 1).  
      # ── word3 (offset 0x0C) ──────────────────────────────────────────  
      - id: border_size  
        type: b1  
        doc: "BitPos=31. Border texel size (0 = no border, 1 = 1-texel border)."  
      - id: reserved3  
        type: b3  
        doc: "BitPos=28. Reserved (3 bits)."  
      - id: aniso_filter  
        type: b3  
        enum: gpu_aniso_filter
        doc: "BitPos=25. Anisotropic filter ratio (GPUANISOFILTER)."  
      - id: mip_filter  
        type: b2  
        enum: gpu_mip_filter
        doc: "BitPos=23. Mip filter (GPUMIPFILTER)."  
      - id: min_filter  
        type: b2  
        enum: gpu_min_mag_filter
        doc: "BitPos=21. Minification filter (GPUMINMAGFILTER)."  
      - id: mag_filter  
        type: b2  
        enum: gpu_min_mag_filter
        doc: "BitPos=19. Magnification filter (GPUMINMAGFILTER)."  
      - id: exp_adjust  
        type: b6  
        doc: "BitPos=13. Exponent bias for float formats (signed two's complement)."  
      - id: swizzle_w  
        type: b3  
        enum: gpu_swizzle
        doc: "BitPos=10. W channel swizzle (GPUSWIZZLE)."  
      - id: swizzle_z  
        type: b3  
        enum: gpu_swizzle
        doc: "BitPos=7. Z channel swizzle (GPUSWIZZLE)."  
      - id: swizzle_y  
        type: b3  
        enum: gpu_swizzle
        doc: "BitPos=4. Y channel swizzle (GPUSWIZZLE)."  
      - id: swizzle_x  
        type: b3  
        enum: gpu_swizzle
        doc: "BitPos=1. X channel swizzle (GPUSWIZZLE)."  
      - id: num_format  
        type: b1  
        doc: "BitPos=0. Numeric format (0 = fraction, 1 = integer)."  
      # ── word4 (offset 0x10) ──────────────────────────────────────────  
      - id: grad_exp_adjust_v  
        type: b5  
        doc: "BitPos=27. Gradient exponent adjust, V axis (signed two's complement)."  
      - id: grad_exp_adjust_h  
        type: b5  
        doc: "BitPos=22. Gradient exponent adjust, H axis (signed two's complement)."  
      - id: lod_bias  
        type: b10  
        doc: "BitPos=12. LOD bias (signed two's complement, 4.6 fixed point)."  
      - id: min_aniso_walk  
        type: b1  
        doc: "BitPos=11. Minimum anisotropic walk enable."  
      - id: mag_aniso_walk  
        type: b1  
        doc: "BitPos=10. Magnification anisotropic walk enable."  
      - id: max_mip_level  
        type: b4  
        doc: |  
          BitPos=6. Maximum mip level index (0-based).  
          D3DBaseTexture::GetLevelCount() returns (max_mip_level + 1).  
          XGOffsetBaseTextureAddress patches mip_address only when  
          max_mip_level > 0 (i.e. level_count > 1).  
      - id: min_mip_level  
        type: b4  
        doc: "BitPos=2. Minimum mip level index (0-based)."  
      - id: vol_min_filter  
        type: b1  
        enum: gpu_min_mag_filter
        doc: "BitPos=1. Volume texture minification filter (0 = point, 1 = linear)."  
      - id: vol_mag_filter  
        type: b1  
        enum: gpu_min_mag_filter
        doc: "BitPos=0. Volume texture magnification filter (0 = point, 1 = linear)."  
      # ── word5 (offset 0x14) ──────────────────────────────────────────  
      - id: mip_address  
        type: b20  
        doc: |  
          BitPos=12. Physical mip surface address >> 12.  
          Patched by XGOffsetBaseTextureAddress when max_mip_level > 0:  
              word5 = (word5 & 0xFFF) | (pMipAddress + (word5 & 0xFFFFF000)) & 0xFFFFF000  
          Zero in the file when no mipmaps are present.  
          Also accessible as D3DResource pThis[2].Common (offset 0x30 from  
          D3DBaseTexture base); (pThis[2].Common & 0xFFFFF000) != 0 means  
          mipmaps are present.  
      - id: packed_mips  
        type: b1  
        doc: "BitPos=11. Mip levels are packed into the base surface."  
      - id: dimension  
        type: b2  
        enum: gpu_dimension
        doc: |  
          BitPos=9. GPUDIMENSION:  
              0 = 1D (line texture)   → size.as_1d  
              1 = 2D (regular/array)  → size.as_2d  
              2 = 3D (volume)         → size.as_3d  
              3 = cube/stack          → size.as_stack  
          Extracted by D3DResource_GetType as (pThis[2].Common >> 9) & 3.  
      - id: aniso_bias  
        type: b4  
        doc: "BitPos=5. Anisotropic LOD bias (signed two's complement)."  
      - id: tri_clamp  
        type: b2  
        enum: gpu_tri_clamp
        doc: "BitPos=3. Trilinear clamp (GPUTRICLAMP)."  
      - id: force_bcw_to_max  
        type: b1  
        doc: "BitPos=2. Force BCW to maximum colour determinant."  
      - id: border_color  
        type: b2  
        enum: gpu_border_color
        doc: "BitPos=0. Border colour preset (GPUBORDERCOLOR)."  
        
  gpu_texture_size:  
    doc: |  
      GPUTEXTURESIZE union (4 bytes). The raw u4 is re-read via instances  
      as the appropriate variant based on gpu_texture_fetch_constant.dimension.  
    seq:  
      - id: raw  
        type: u4  
    instances:  
      as_1d:  
        pos: 0  
        type: gpu_texture_size_1d  
        doc: Valid when dimension == 0 (1D / line texture).  
      as_2d:  
        pos: 0  
        type: gpu_texture_size_2d  
        doc: Valid when dimension == 1 (2D texture).  
      as_3d:  
        pos: 0  
        type: gpu_texture_size_3d  
        doc: Valid when dimension == 2 (3D / volume texture).  
      as_stack:  
        pos: 0  
        type: gpu_texture_size_stack  
        doc: Valid when dimension == 3 (cube / stacked texture).  
  
  gpu_texture_size_1d:  
    doc: "GPUTEXTURESIZE_1D — 1D (line) texture. Width : 24 at BitPos=0."  
    seq:  
      - id: reserved  
        type: b8  
        doc: Bits [31:24] — unused.  
      - id: width  
        type: b24  
        doc: "BitPos=0. Texture width in texels, minus 1."  
  
  gpu_texture_size_2d:  
    doc: "GPUTEXTURESIZE_2D — 2D texture. Width : 13 at BitPos=0, Height : 13 at BitPos=13."  
    seq:  
      - id: reserved  
        type: b6  
        doc: Bits [31:26] — unused.  
      - id: height  
        type: b13  
        doc: "BitPos=13. Texture height in texels, minus 1."  
      - id: width  
        type: b13  
        doc: "BitPos=0. Texture width in texels, minus 1."  
  
  gpu_texture_size_3d:  
    doc: "GPUTEXTURESIZE_3D — 3D (volume) texture. Width:11, Height:11, Depth:10."  
    seq:  
      - id: depth  
        type: b10  
        doc: "BitPos=22. Texture depth in slices, minus 1."  
      - id: height  
        type: b11  
        doc: "BitPos=11. Texture height in texels, minus 1."  
      - id: width  
        type: b11  
        doc: "BitPos=0. Texture width in texels, minus 1."  
  
  gpu_texture_size_stack:  
    doc: "GPUTEXTURESIZE_STACK — stacked/cube texture. Width:13, Height:13, Depth:6."  
    seq:  
      - id: depth  
        type: b6  
        doc: "BitPos=26. Number of array slices, minus 1."  
      - id: height  
        type: b13  
        doc: "BitPos=13. Texture height in texels, minus 1."  
      - id: width  
        type: b13  
        doc: "BitPos=0. Texture width in texels, minus 1."

enums:  
  gpuclamp:  
    0: wrap  
    1: mirror  
    2: clamp_to_last  
    3: mirror_once_to_last  
    4: clamp_halfway  
    5: mirror_once_halfway  
    6: clamp_to_border  
    7: mirror_to_border

  gpusign:  
    0: unsigned  
    1: signed  
    2: bias #	Indicates that a value is unsigned biased. GPUSIGN_BIAS maps an UNSIGNED value with a range of 0 to 1 into a range of -1 to 1. The equation used to perform the mapping is 2 * x - 1. For example, the UNSIGNED values 0, 0.5 and 1 would map to -1, 0 and 1.
    3: gamma # Indicates that a value is unsigned gamma corrected.

  gpuconstanttype:  
    0: invalid_texture  
    1: invalid_vertex  
    2: texture  
    3: vertex

  gpuendian:  
    0: none  
    1: e_8_in_16 # Every 8 bits in a 16-bit word are swapped. For example, 0xAABBCCDD would be changed to 0xBBAADDCC.
    2: e_8_in_32 # Every 8 bits in a 32-bit word are swapped. For example, 0xAABBCCDD would be changed to 0xDDCCBBAA.
    3: e_16_in_32 # Every 16 bits in a 32-bit word are swapped. For example, 0xAABBCCDD would be changed to 0xCCDDAABB.

  gpu_texture_format:  
    0x00: fmt_1_reverse  
    0x01: fmt_1  
    0x02: fmt_8  
    0x03: fmt_1_5_5_5  
    0x04: fmt_5_6_5  
    0x05: fmt_6_5_5  
    0x06: fmt_8_8_8_8  
    0x07: fmt_2_10_10_10  
    0x08: fmt_8_a  
    0x09: fmt_8_b  
    0x0a: fmt_8_8  
    0x0b: cr_y1_cb_y0_rep  
    0x0c: y1_cr_y0_cb_rep  
    0x0d: fmt_16_16_edram  
    0x0e: fmt_8_8_8_8_a  
    0x0f: fmt_4_4_4_4  
    0x10: fmt_10_11_11  
    0x11: fmt_11_11_10  
    0x12: dxt1  
    0x13: dxt2_3  
    0x14: dxt4_5  
    0x15: fmt_16_16_16_16_edram  
    0x16: fmt_24_8  
    0x17: fmt_24_8_float  
    0x18: fmt_16  
    0x19: fmt_16_16  
    0x1a: fmt_16_16_16_16  
    0x1b: fmt_16_expand  
    0x1c: fmt_16_16_expand  
    0x1d: fmt_16_16_16_16_expand  
    0x1e: fmt_16_float  
    0x1f: fmt_16_16_float  
    0x20: fmt_16_16_16_16_float  
    0x21: fmt_32  
    0x22: fmt_32_32  
    0x23: fmt_32_32_32_32  
    0x24: fmt_32_float  
    0x25: fmt_32_32_float  
    0x26: fmt_32_32_32_32_float  
    0x27: fmt_32_as_8  
    0x28: fmt_32_as_8_8  
    0x29: fmt_16_mpeg  
    0x2a: fmt_16_16_mpeg  
    0x2b: fmt_8_interlaced  
    0x2c: fmt_32_as_8_interlaced  
    0x2d: fmt_32_as_8_8_interlaced  
    0x2e: fmt_16_interlaced  
    0x2f: fmt_16_mpeg_interlaced  
    0x30: fmt_16_16_mpeg_interlaced  
    0x31: dxn  
    0x32: fmt_8_8_8_8_as_16_16_16_16  
    0x33: dxt1_as_16_16_16_16  
    0x34: dxt2_3_as_16_16_16_16  
    0x35: dxt4_5_as_16_16_16_16  
    0x36: fmt_2_10_10_10_as_16_16_16_16  
    0x37: fmt_10_11_11_as_16_16_16_16  
    0x38: fmt_11_11_10_as_16_16_16_16  
    0x39: fmt_32_32_32_float  
    0x3a: dxt3a  
    0x3b: dxt5a  
    0x3c: ctx1  
    0x3d: dxt3a_as_1_1_1_1  
    0x3e: fmt_8_8_8_8_gamma_edram  
    0x3f: fmt_2_10_10_10_float_edram

  gpu_aniso_filter:  
    0x00: disabled  
    0x01: max1to1  
    0x02: max2to1  
    0x03: max4to1  
    0x04: max8to1  
    0x05: max16to1  
    0x07: keep

  gpu_mip_filter:  
    0x00: point  
    0x01: linear  
    0x02: basemap  
    0x03: keep

  gpu_min_mag_filter:  
    0x00: point  
    0x01: linear  
    0x03: keep

  gpu_swizzle:  
    0x00: x  
    0x01: y  
    0x02: z  
    0x03: w  
    0x04: const_0  
    0x05: const_1  
    0x07: keep

  gpu_dimension:  
    0x00: 'dim_1d'  
    0x01: 'dim_2d'  
    0x02: 'dim_3d'  
    0x03: 'cubemap'

  gpu_tri_clamp:  
    0x00: 'normal'  
    0x01: 'one_sixth'  
    0x02: 'one_fourth'  
    0x03: 'three_eighths'
  
  gpu_border_color:  
    0x00: 'abgr_black'  
    0x01: 'abgr_white'  
    0x02: 'acbycr_black'  
    0x03: 'acbcry_black'