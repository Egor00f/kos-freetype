;;================================================================================================;;
;;//// scale.asm //// (c) dunkaist, 2012 /////////////////////////////////////////////////////////;;
;;================================================================================================;;
;;                                                                                                ;;
;; This file is part of Common development libraries (Libs-Dev).                                  ;;
;;                                                                                                ;;
;; Libs-Dev is free software: you can redistribute it and/or modify it under the terms of the GNU ;;
;; Lesser General Public License as published by the Free Software Foundation, either version 2.1 ;;
;; of the License, or (at your option) any later version.                                         ;;
;;                                                                                                ;;
;; Libs-Dev is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without  ;;
;; even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU  ;;
;; Lesser General Public License for more details.                                                ;;
;;                                                                                                ;;
;; You should have received a copy of the GNU Lesser General Public License along with Libs-Dev.  ;;
;; If not, see <http://www.gnu.org/licenses/>.                                                    ;;
;;                                                                                                ;;
;;================================================================================================;;

;;================================================================================================;;
proc img.scale _src, _crop_x, _crop_y, _crop_width, _crop_height, _dst, _scale_type, _scale_alg, _param1, _param2 ;;
;;------------------------------------------------------------------------------------------------;;
;? scale _image                                                                                   ;;
;;------------------------------------------------------------------------------------------------;;
;> [_src]         = pointer to source image                                                       ;;
;> [_crop_x]      = left coord of cropping rect                                                   ;;
;> [_crop_y]      = top coord of cropping rect                                                    ;;
;> [_crop_width]  = width of cropping rect                                                        ;;
;> [_crop_height] = height of cropping rect                                                       ;;
;> [_dst]         = pointer to resulting image / 0                                                ;;
;> [_scale_type]  = how to change width and height. see libimg.inc                                ;;
;> [_scale_alg]   = algorithm to use. see libimg.inc                                              ;;
;> [_param1]      = the first argument passed to _scale_alg algorithm                             ;;
;> [_param2]      = the second argument passed to _scale_alg algorithm                            ;;
;;------------------------------------------------------------------------------------------------;;
;< eax = 0 / pointer to scaled image                                                              ;;
;< ecx = error code / undefined                                                                   ;;
;;================================================================================================;;
locals
	src_type		rd 1
	src_data		rd 1
	dst_data		rd 1

	src_width_pixels	rd 1
	src_width_bytes		rd 1
	src_height_pixels	rd 1

	scl_width_pixels	rd 1
	scl_width_pixels_inv	rd 1
	scl_height_pixels	rd 1
	scl_height_pixels_inv	rd 1
	scl_width_bytes		rd 1
	bytes_per_pixel		rd 1

	crop_width_pixels_m1	rd 1
	crop_height_pixels_m1	rd 1
; bilinear
	src_x			rd 1
	src_y			rd 1
	src_base		rd 1
	dst_x			rd 1
	dst_y			rd 1
	rem_x			rd 1
	rem_y			rd 1
endl
	mov	ebx, [_src]
	push	[ebx + Image.Width]
	pop	[src_width_pixels]
	push	[ebx + Image.Height]
	pop	[src_height_pixels]
	push	[ebx + Image.Type]
	pop	[src_type]
	push	[ebx + Image.Data]
	pop	[src_data]

	mov	eax, [src_type]
	mov	ecx, [src_width_pixels]
	mov	edx, [src_width_pixels]
	imul	edx, [_crop_y]
	add	edx, [_crop_x]
	cmp	eax, Image.bpp32
	jne	@f
	mov	[bytes_per_pixel], 4
	shl	ecx, 2
	shl	edx, 2
	jmp	.lab1
    @@:
	cmp	eax, Image.bpp24
	jne	@f
	mov	[bytes_per_pixel], 3
	lea	ecx, [ecx*3]
	lea	edx, [ecx*3]
	jmp	.lab1
    @@:
	cmp	eax, Image.bpp8g
	jne	@f
	mov	[bytes_per_pixel], 1
	jmp	.lab1
    @@:
	mov	ecx, LIBIMG_ERROR_BIT_DEPTH
	jmp	.error
  .lab1:
	mov	[src_width_bytes], ecx
	add	[src_data], edx


	mov	eax, [_scale_alg]
	cmp	eax, LIBIMG_SCALE_ALG_INTEGER
	je	.integer
	cmp	eax, LIBIMG_SCALE_ALG_BILINEAR
	je	.bilinear
	mov	ecx, LIBIMG_ERROR_SCALE_ALG
	jmp	.error

  .integer:
	mov	eax, [_param1]
	mov	ecx, [_crop_width]
	imul	ecx, eax
	mov	[scl_width_pixels], ecx
	mov	edx, [_crop_height]
	imul	edx, eax
	mov	[scl_height_pixels], edx

	mov	eax, [_dst]
	test	eax, eax
	jnz	@f
	stdcall	img.create, [scl_width_pixels], [scl_height_pixels], [src_type]
	test	eax, eax
	jz	.error
	mov	[_dst], eax
    @@:
	mov	edi, [eax + Image.Data]
	mov	[dst_data], edi

	mov	esi, [src_data]
	mov	eax, [src_type]
	cmp	eax, Image.bpp8g
	je	.integer.bpp8g
	cmp	eax, Image.bpp24
	je	.integer.bpp24
	cmp	eax, Image.bpp32
	je	.integer.bpp32
	mov	ecx, LIBIMG_ERROR_BIT_DEPTH
	jmp	.error

  .integer.bpp8g:
	push	[scl_width_pixels]
	pop	[scl_width_bytes]
	mov	ecx, [_param1]
;	cmp	ecx, 1
;	je	.error
  .integer.bpp8g.common:
	mov	edx, ecx
	mov	ebx, [_crop_height]
  .integer.bpp8g.common.line:
	push	ebx
	mov	ebx, [_crop_width]
    @@:
	lodsb
	mov	ecx, edx
	rep	stosb
	dec	ebx
	jnz	@b
	push	esi
	mov	esi, edi
	sub	esi, [scl_width_bytes]
	mov	ecx, edx
	dec	ecx
	imul	ecx, [scl_width_bytes]
	mov	eax, ecx
	shr	ecx, 2
	and	eax, 0x00000003
	rep	movsd
	mov	ecx, eax
	rep	movsb
	pop	esi
	mov	eax, [src_width_pixels]
	sub	eax, [_crop_width]
	add	esi, eax
	pop	ebx
	dec	ebx
	jnz	.integer.bpp8g.common.line
	mov	eax, [_dst]
	jmp	.quit

  .integer.bpp24:
	mov	eax, [scl_width_pixels]
	lea	eax, [eax*3]
	mov	[scl_width_bytes], eax
	mov	ecx, [_param1]
;	cmp	ecx, 1
;	je	.error
  .integer.bpp24.common:
	mov	edx, ecx
	mov	ebx, [_crop_height]
  .integer.bpp24.common.line:
	push	ebx
	mov	ebx, [_crop_width]
    @@:
	movsw
	movsb
	mov	ecx, edx
	push	esi
	mov	esi, edi
	sub	esi, 3
	dec	ecx
	lea	ecx, [ecx*3]
	rep	movsb
	pop	esi
	dec	ebx
	jnz	@b
	push	esi
	mov	esi, edi
	sub	esi, [scl_width_bytes]
	mov	ecx, edx
	dec	ecx
	imul	ecx, [scl_width_bytes]
	mov	eax, ecx
	shr	ecx, 2
	and	eax, 0x00000003
	rep	movsd
	mov	ecx, eax
	rep	movsb
	pop	esi
	mov	eax, [src_width_pixels]
	sub	eax, [_crop_width]
	lea	eax, [eax*3]
	add	esi, eax
	pop	ebx
	dec	ebx
	jnz	.integer.bpp24.common.line
	mov	eax, [_dst]
	jmp	.quit

  .integer.bpp32:
	mov	eax, [scl_width_pixels]
	shl	eax, 2
	mov	[scl_width_bytes], eax
	mov	ecx, [_param1]
;	cmp	ecx, 1
;	je	.error
  .integer.bpp32.common:
	mov	edx, ecx
	mov	ebx, [_crop_height]
  .integer.bpp32.common.line:
	push	ebx
	mov	ebx, [_crop_width]
    @@:
	lodsd
	mov	ecx, edx
	rep	stosd
	dec	ebx
	jnz	@b
	push	esi
	mov	esi, edi
	sub	esi, [scl_width_bytes]
	mov	ecx, edx
	dec	ecx
	imul	ecx, [scl_width_bytes]
	shr	ecx, 2
	rep	movsd
	pop	esi
	mov	eax, [src_width_pixels]
	sub	eax, [_crop_width]
	shl	eax, 2
	add	esi, eax
	pop	ebx
	dec	ebx
	jnz	.integer.bpp32.common.line
	mov	eax, [_dst]
	jmp	.quit


  .bilinear:
	mov	eax, [_scale_type]
	cmp	eax, LIBIMG_SCALE_TYPE_FIT_RECT
	je	.bilinear.fit_rect
	cmp	eax, LIBIMG_SCALE_TYPE_FIT_WIDTH
	je	.bilinear.fit_width
	cmp	eax, LIBIMG_SCALE_TYPE_FIT_HEIGHT
	je	.bilinear.fit_height
	cmp	eax, LIBIMG_SCALE_TYPE_FIT_MAX
	je	.bilinear.fit_max
	cmp	eax, LIBIMG_SCALE_TYPE_STRETCH
	je	.bilinear.stretch
	mov	ecx, LIBIMG_ERROR_SCALE_TYPE
	jmp	.error
  .bilinear.fit_rect:
	mov	eax, [_param1]
	shl	eax, 16
	add	eax, 0x00008000
	xor	edx, edx
	div	[src_width_pixels]
	mov	ebx, eax
	mov	eax, [_param2]
	shl	eax, 16
	add	eax, 0x00008000
	xor	edx, edx
	div	[src_height_pixels]
	mov	ecx, eax
	cmp	ebx, ecx
	jb	@f
	mov	ebx, ecx
    @@:
	jmp	.bilinear.fit_common
  .bilinear.fit_max:
	mov	eax, [_param1]
	shl	eax, 16
	add	eax, 0x00008000
	xor	edx, edx
	div	[src_width_pixels]
	mov	ebx, eax
	mov	eax, [_param2]
	shl	eax, 16
	add	eax, 0x00008000
	xor	edx, edx
	div	[src_height_pixels]
	mov	ecx, eax
	cmp	ebx, ecx
	ja	@f
	mov	ebx, ecx
    @@:
	jmp	.bilinear.fit_common
  .bilinear.fit_width:
	mov	eax, [_param1]
	shl	eax, 16
	add	eax, 0x00008000
	xor	edx, edx
	div	[src_width_pixels]
	mov	ebx, eax
	jmp	.bilinear.fit_common
  .bilinear.fit_height:
	mov	eax, [_param2]
	shl	eax, 16
	add	eax, 0x00008000
	xor	edx, edx
	div	[src_height_pixels]
	mov	ebx, eax
	jmp	.bilinear.fit_common
  .bilinear.fit_common:
	mov	eax, [src_width_pixels]
	mul	ebx
	shr	eax, 16
	mov	[scl_width_pixels], eax
	imul	eax, [bytes_per_pixel]
	mov	[scl_width_bytes], eax
	mov	eax, [src_height_pixels]
	mul	ebx
	shr	eax, 16
	mov	[scl_height_pixels], eax
	jmp	.bilinear.common
  .bilinear.stretch:
	mov	eax, [_param1]
	mov	[scl_width_pixels], eax
	imul	eax, [bytes_per_pixel]
	mov	[scl_width_bytes], eax
	mov	ecx, [_param2]
	mov	[scl_height_pixels], ecx
	jmp	.bilinear.common

  .bilinear.common:
	mov	eax, [_dst]
	test	eax, eax
	jnz	@f
	stdcall	img.create, [scl_width_pixels], [scl_height_pixels], [src_type]
	test	eax, eax
	jz	.error
	mov	[_dst], eax
    @@:
	mov	edi, [eax + Image.Data]
	mov	[dst_data], edi

	push	[_crop_width]
	pop	[crop_width_pixels_m1]
	sub	[crop_width_pixels_m1], 1
	push	[_crop_height]
	pop	[crop_height_pixels_m1]
	sub	[crop_height_pixels_m1], 1

	mov	eax, 0xffffffff
	xor	edx, edx
	div	[scl_width_pixels]
	mov	[scl_width_pixels_inv], eax
	mov	eax, 0xffffffff
	xor	edx, edx
	div	[scl_height_pixels]
	mov	[scl_height_pixels_inv], eax

	mov	eax, [src_type]
	cmp	eax, Image.bpp8g
	je	.bilinear.bpp8g
	cmp	eax, Image.bpp24
	je	.bilinear.bpp24
	cmp	eax, Image.bpp32
	je	.bilinear.bpp32
	mov	ecx, LIBIMG_ERROR_BIT_DEPTH
	jmp	.error

  .bilinear.bpp8g:
	mov	esi, [src_data]
	mov	[dst_y], 0
	mov	eax, 0	; mov eax, [dst_y]
  .bilinear.bpp8g.line:
	mov	esi, [src_data]
	mov	[dst_x], 0
	imul	eax, [crop_height_pixels_m1]
	xor	edx, edx
	div	[scl_height_pixels]
	mov	[rem_y], edx
	imul	eax, [src_width_bytes]
	add	esi, eax
	mov	[src_base], esi
	mov	eax, 0	; mov eax, [dst_x]

  .bilinear.bpp8g.pixel:
	mov	esi, [src_base]

	imul	eax, [crop_width_pixels_m1]
	xor	edx, edx
	div	[scl_width_pixels]
	add	esi, eax

	mov	ax, word[esi]
	add	esi, [src_width_pixels]
	mov	bx, word[esi]
	mov	esi, edx
	movzx	edx, ah
	and	eax, 0x000000ff
	movzx	ecx, bh
	and	ebx, 0x000000ff

	imul	edx, esi
	imul	ecx, esi
	neg	esi
	add	esi, [scl_width_pixels]
	imul	eax, esi
	imul	ebx, esi
	add	eax, edx
	add	ebx, ecx
	mov	esi, [scl_width_pixels_inv]
	mul	esi
	mov	ecx, edx
	mov	eax, ebx
	mul	esi
	mov	eax, edx

	mov	edx, [rem_y]
	imul	eax, edx
	neg	edx
	add	edx, [scl_height_pixels]
	imul	ecx, edx
	add	eax, ecx
	mul	[scl_height_pixels_inv]
	mov	byte[edi], dl
	add	edi, 1

	add	[dst_x], 1
	mov	eax, [dst_x]
	cmp	eax, [scl_width_pixels]
	jne	.bilinear.bpp8g.pixel

	add	[dst_y], 1
	mov	eax, [dst_y]
	cmp	eax, [scl_height_pixels]
	jne	.bilinear.bpp8g.line

	mov	eax, [_dst]
	jmp	.quit


  .bilinear.bpp24:
	mov	esi, [src_data]
	mov	[dst_y], 0
	mov	eax, 0	; mov eax, [dst_y]
  .bilinear.bpp24.line:
	mov	esi, [src_data]
	mov	[dst_x], 0
	imul	eax, [crop_height_pixels_m1]
	xor	edx, edx
	div	[scl_height_pixels]
	mov	[rem_y], edx
	imul	eax, [src_width_bytes]
	add	esi, eax
	mov	[src_base], esi
	mov	eax, 0	; mov eax, [dst_x]

  .bilinear.bpp24.pixel:
	mov	esi, [src_base]

	imul	eax, [crop_width_pixels_m1]
	xor	edx, edx
	div	[scl_width_pixels]
	lea	eax, [eax*3]
	add	esi, eax

	mov	[rem_x], edx
	sub	esi, 1
	mov	[src_x], esi

repeat 3
	mov	edx, [rem_x]
	add	[src_x], 1
	mov	esi, [src_x]

	mov	al, byte[esi]
	mov	ah, byte[esi + 3]
	add	esi, [src_width_bytes]
	movzx	ebx, byte[esi]
	movzx	ecx, byte[esi + 3]
	mov	esi, edx
	movzx	edx, ah
	and	eax, 0x000000ff

	imul	edx, esi
	imul	ecx, esi
	neg	esi
	add	esi, [scl_width_pixels]
	imul	eax, esi
	imul	ebx, esi
	add	eax, edx
	add	ebx, ecx
	mov	esi, [scl_width_pixels_inv]
	mul	esi
	mov	ecx, edx
	mov	eax, ebx
	mul	esi
	mov	eax, edx

	mov	edx, [rem_y]
	imul	eax, edx
	neg	edx
	add	edx, [scl_height_pixels]
	imul	ecx, edx
	add	eax, ecx
	mul	[scl_height_pixels_inv]
	mov	byte[edi], dl
	add	edi, 1
end repeat

	add	[dst_x], 1
	mov	eax, [dst_x]
	cmp	eax, [scl_width_pixels]
	jne	.bilinear.bpp24.pixel

	add	[dst_y], 1
	mov	eax, [dst_y]
	cmp	eax, [scl_height_pixels]
	jne	.bilinear.bpp24.line

	mov	eax, [_dst]
	jmp	.quit

  .bilinear.bpp32:
	mov	esi, [src_data]
	mov	[dst_y], 0
	mov	eax, 0	; mov eax, [dst_y]
  .bilinear.bpp32.line:
	mov	esi, [src_data]
	mov	[dst_x], 0
	imul	eax, [crop_height_pixels_m1]
	xor	edx, edx
	div	[scl_height_pixels]
	mov	[rem_y], edx
	imul	eax, [src_width_bytes]
	add	esi, eax
	mov	[src_base], esi
	mov	eax, 0	; mov eax, [dst_x]

  .bilinear.bpp32.pixel:
	mov	esi, [src_base]

	imul	eax, [crop_width_pixels_m1]
	xor	edx, edx
	div	[scl_width_pixels]
	shl	eax, 2
	add	esi, eax

	mov	[rem_x], edx
	sub	esi, 1
	mov	[src_x], esi

repeat 4
	mov	edx, [rem_x]
	add	[src_x], 1
	mov	esi, [src_x]

	mov	al, byte[esi]
	mov	ah, byte[esi + 4]
	add	esi, [src_width_bytes]
	movzx	ebx, byte[esi]
	movzx	ecx, byte[esi + 4]
	mov	esi, edx
	movzx	edx, ah
	and	eax, 0x000000ff

	imul	edx, esi
	imul	ecx, esi
	neg	esi
	add	esi, [scl_width_pixels]
	imul	eax, esi
	imul	ebx, esi
	add	eax, edx
	add	ebx, ecx
	mov	esi, [scl_width_pixels_inv]
	mul	esi
	mov	ecx, edx
	mov	eax, ebx
	mul	esi
	mov	eax, edx

	mov	edx, [rem_y]
	imul	eax, edx
	neg	edx
	add	edx, [scl_height_pixels]
	imul	ecx, edx
	add	eax, ecx
	mul	[scl_height_pixels_inv]
	mov	byte[edi], dl
	add	edi, 1
end repeat

	add	[dst_x], 1
	mov	eax, [dst_x]
	cmp	eax, [scl_width_pixels]
	jne	.bilinear.bpp32.pixel

	add	[dst_y], 1
	mov	eax, [dst_y]
	cmp	eax, [scl_height_pixels]
	jne	.bilinear.bpp32.line

	mov	eax, [_dst]
	jmp	.quit


  .error:
	xor	eax, eax
  .quit:
	ret

endp

