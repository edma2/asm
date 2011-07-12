; 4-jumptable.c w/ gcc optimizations for size, 32-bit x86
; A comparison of implementations for large conditional statements.
;       switch statements
;       function pointers
;       goto labels
; Assembly output commented by Eugene Ma
; gcc -Os 4-jumptable.c && objdump -D a.out > 4-jumptable_OsOpt.s

a.out:     file format elf32-i386


Disassembly of section .interp:

08048134 <.interp>:
 8048134:	2f                   	das    
 8048135:	6c                   	insb   (%dx),%es:(%edi)
 8048136:	69 62 2f 6c 64 2d 6c 	imul   $0x6c2d646c,0x2f(%edx),%esp
 804813d:	69 6e 75 78 2e 73 6f 	imul   $0x6f732e78,0x75(%esi),%ebp
 8048144:	2e 32 00             	xor    %cs:(%eax),%al

Disassembly of section .note.ABI-tag:

08048148 <.note.ABI-tag>:
 8048148:	04 00                	add    $0x0,%al
 804814a:	00 00                	add    %al,(%eax)
 804814c:	10 00                	adc    %al,(%eax)
 804814e:	00 00                	add    %al,(%eax)
 8048150:	01 00                	add    %eax,(%eax)
 8048152:	00 00                	add    %al,(%eax)
 8048154:	47                   	inc    %edi
 8048155:	4e                   	dec    %esi
 8048156:	55                   	push   %ebp
 8048157:	00 00                	add    %al,(%eax)
 8048159:	00 00                	add    %al,(%eax)
 804815b:	00 02                	add    %al,(%edx)
 804815d:	00 00                	add    %al,(%eax)
 804815f:	00 06                	add    %al,(%esi)
 8048161:	00 00                	add    %al,(%eax)
 8048163:	00 1b                	add    %bl,(%ebx)
 8048165:	00 00                	add    %al,(%eax)
	...

Disassembly of section .note.gnu.build-id:

08048168 <.note.gnu.build-id>:
 8048168:	04 00                	add    $0x0,%al
 804816a:	00 00                	add    %al,(%eax)
 804816c:	14 00                	adc    $0x0,%al
 804816e:	00 00                	add    %al,(%eax)
 8048170:	03 00                	add    (%eax),%eax
 8048172:	00 00                	add    %al,(%eax)
 8048174:	47                   	inc    %edi
 8048175:	4e                   	dec    %esi
 8048176:	55                   	push   %ebp
 8048177:	00 bd 67 5c 14 f9    	add    %bh,-0x6eba399(%ebp)
 804817d:	44                   	inc    %esp
 804817e:	d3 bf 38 28 dd a3    	sarl   %cl,-0x5c22d7c8(%edi)
 8048184:	1c 67                	sbb    $0x67,%al
 8048186:	6f                   	outsl  %ds:(%esi),(%dx)
 8048187:	11 16                	adc    %edx,(%esi)
 8048189:	9c                   	pushf  
 804818a:	29                   	.byte 0x29
 804818b:	40                   	inc    %eax

Disassembly of section .hash:

0804818c <.hash>:
 804818c:	03 00                	add    (%eax),%eax
 804818e:	00 00                	add    %al,(%eax)
 8048190:	07                   	pop    %es
 8048191:	00 00                	add    %al,(%eax)
 8048193:	00 01                	add    %al,(%ecx)
 8048195:	00 00                	add    %al,(%eax)
 8048197:	00 04 00             	add    %al,(%eax,%eax,1)
 804819a:	00 00                	add    %al,(%eax)
 804819c:	03 00                	add    (%eax),%eax
	...
 80481aa:	00 00                	add    %al,(%eax)
 80481ac:	06                   	push   %es
 80481ad:	00 00                	add    %al,(%eax)
 80481af:	00 02                	add    %al,(%edx)
 80481b1:	00 00                	add    %al,(%eax)
 80481b3:	00 00                	add    %al,(%eax)
 80481b5:	00 00                	add    %al,(%eax)
 80481b7:	00                   	.byte 0x0
 80481b8:	05                   	.byte 0x5
 80481b9:	00 00                	add    %al,(%eax)
	...

Disassembly of section .gnu.hash:

080481bc <.gnu.hash>:
 80481bc:	02 00                	add    (%eax),%al
 80481be:	00 00                	add    %al,(%eax)
 80481c0:	05 00 00 00 01       	add    $0x1000000,%eax
 80481c5:	00 00                	add    %al,(%eax)
 80481c7:	00 05 00 00 00 00    	add    %al,0x0
 80481cd:	21 04 20             	and    %eax,(%eax,%eiz,1)
 80481d0:	05 00 00 00 06       	add    $0x6000000,%eax
 80481d5:	00 00                	add    %al,(%eax)
 80481d7:	00 49 6a             	add    %cl,0x6a(%ecx)
 80481da:	88 0b                	mov    %cl,(%ebx)
 80481dc:	ad                   	lods   %ds:(%esi),%eax
 80481dd:	4b                   	dec    %ebx
 80481de:	e3 c0                	jecxz  80481a0 <_init-0x15c>

Disassembly of section .dynsym:

080481e0 <.dynsym>:
	...
 80481f0:	01 00                	add    %eax,(%eax)
	...
 80481fa:	00 00                	add    %al,(%eax)
 80481fc:	20 00                	and    %al,(%eax)
 80481fe:	00 00                	add    %al,(%eax)
 8048200:	39 00                	cmp    %eax,(%eax)
	...
 804820a:	00 00                	add    %al,(%eax)
 804820c:	12 00                	adc    (%eax),%al
 804820e:	00 00                	add    %al,(%eax)
 8048210:	32 00                	xor    (%eax),%al
	...
 804821a:	00 00                	add    %al,(%eax)
 804821c:	12 00                	adc    (%eax),%al
 804821e:	00 00                	add    %al,(%eax)
 8048220:	29 00                	sub    %eax,(%eax)
	...
 804822a:	00 00                	add    %al,(%eax)
 804822c:	12 00                	adc    (%eax),%al
 804822e:	00 00                	add    %al,(%eax)
 8048230:	2e 00 00             	add    %al,%cs:(%eax)
 8048233:	00 6b 84             	add    %ch,-0x7c(%ebx)
 8048236:	04 08                	add    $0x8,%al
 8048238:	0c 00                	or     $0x0,%al
 804823a:	00 00                	add    %al,(%eax)
 804823c:	12 00                	adc    (%eax),%al
 804823e:	0e                   	push   %cs
 804823f:	00 1a                	add    %bl,(%edx)
 8048241:	00 00                	add    %al,(%eax)
 8048243:	00 3c 87             	add    %bh,(%edi,%eax,4)
 8048246:	04 08                	add    $0x8,%al
 8048248:	04 00                	add    $0x0,%al
 804824a:	00 00                	add    %al,(%eax)
 804824c:	11 00                	adc    %eax,(%eax)
 804824e:	10 00                	adc    %al,(%eax)

Disassembly of section .dynstr:

08048250 <.dynstr>:
 8048250:	00 5f 5f             	add    %bl,0x5f(%edi)
 8048253:	67 6d                	insl   (%dx),%es:(%di)
 8048255:	6f                   	outsl  %ds:(%esi),(%dx)
 8048256:	6e                   	outsb  %ds:(%esi),(%dx)
 8048257:	5f                   	pop    %edi
 8048258:	73 74                	jae    80482ce <_init-0x2e>
 804825a:	61                   	popa   
 804825b:	72 74                	jb     80482d1 <_init-0x2b>
 804825d:	5f                   	pop    %edi
 804825e:	5f                   	pop    %edi
 804825f:	00 6c 69 62          	add    %ch,0x62(%ecx,%ebp,2)
 8048263:	63 2e                	arpl   %bp,(%esi)
 8048265:	73 6f                	jae    80482d6 <_init-0x26>
 8048267:	2e 36 00 5f 49       	cs add %bl,%cs:%ss:0x49(%edi)
 804826c:	4f                   	dec    %edi
 804826d:	5f                   	pop    %edi
 804826e:	73 74                	jae    80482e4 <_init-0x18>
 8048270:	64 69 6e 5f 75 73 65 	imul   $0x64657375,%fs:0x5f(%esi),%ebp
 8048277:	64 
 8048278:	00 70 75             	add    %dh,0x75(%eax)
 804827b:	74 73                	je     80482f0 <_init-0xc>
 804827d:	00 64 69 76          	add    %ah,0x76(%ecx,%ebp,2)
 8048281:	00 70 72             	add    %dh,0x72(%eax)
 8048284:	69 6e 74 66 00 5f 5f 	imul   $0x5f5f0066,0x74(%esi),%ebp
 804828b:	6c                   	insb   (%dx),%es:(%edi)
 804828c:	69 62 63 5f 73 74 61 	imul   $0x6174735f,0x63(%edx),%esp
 8048293:	72 74                	jb     8048309 <_init+0xd>
 8048295:	5f                   	pop    %edi
 8048296:	6d                   	insl   (%dx),%es:(%edi)
 8048297:	61                   	popa   
 8048298:	69 6e 00 47 4c 49 42 	imul   $0x42494c47,0x0(%esi),%ebp
 804829f:	43                   	inc    %ebx
 80482a0:	5f                   	pop    %edi
 80482a1:	32 2e                	xor    (%esi),%ch
 80482a3:	30 00                	xor    %al,(%eax)

Disassembly of section .gnu.version:

080482a6 <.gnu.version>:
 80482a6:	00 00                	add    %al,(%eax)
 80482a8:	00 00                	add    %al,(%eax)
 80482aa:	02 00                	add    (%eax),%al
 80482ac:	02 00                	add    (%eax),%al
 80482ae:	02 00                	add    (%eax),%al
 80482b0:	01 00                	add    %eax,(%eax)
 80482b2:	01 00                	add    %eax,(%eax)

Disassembly of section .gnu.version_r:

080482b4 <.gnu.version_r>:
 80482b4:	01 00                	add    %eax,(%eax)
 80482b6:	01 00                	add    %eax,(%eax)
 80482b8:	10 00                	adc    %al,(%eax)
 80482ba:	00 00                	add    %al,(%eax)
 80482bc:	10 00                	adc    %al,(%eax)
 80482be:	00 00                	add    %al,(%eax)
 80482c0:	00 00                	add    %al,(%eax)
 80482c2:	00 00                	add    %al,(%eax)
 80482c4:	10 69 69             	adc    %ch,0x69(%ecx)
 80482c7:	0d 00 00 02 00       	or     $0x20000,%eax
 80482cc:	4b                   	dec    %ebx
 80482cd:	00 00                	add    %al,(%eax)
 80482cf:	00 00                	add    %al,(%eax)
 80482d1:	00 00                	add    %al,(%eax)
	...

Disassembly of section .rel.dyn:

080482d4 <.rel.dyn>:
 80482d4:	f0 9c                	lock pushf 
 80482d6:	04 08                	add    $0x8,%al
 80482d8:	06                   	push   %es
 80482d9:	01 00                	add    %eax,(%eax)
	...

Disassembly of section .rel.plt:

080482dc <.rel.plt>:
 80482dc:	00 9d 04 08 07 01    	add    %bl,0x1070804(%ebp)
 80482e2:	00 00                	add    %al,(%eax)
 80482e4:	04 9d                	add    $0x9d,%al
 80482e6:	04 08                	add    $0x8,%al
 80482e8:	07                   	pop    %es
 80482e9:	02 00                	add    (%eax),%al
 80482eb:	00 08                	add    %cl,(%eax)
 80482ed:	9d                   	popf   
 80482ee:	04 08                	add    $0x8,%al
 80482f0:	07                   	pop    %es
 80482f1:	03 00                	add    (%eax),%eax
 80482f3:	00 0c 9d 04 08 07 04 	add    %cl,0x4070804(,%ebx,4)
	...

Disassembly of section .init:

080482fc <_init>:
 80482fc:	53                   	push   %ebx
 80482fd:	83 ec 08             	sub    $0x8,%esp
 8048300:	e8 00 00 00 00       	call   8048305 <_init+0x9>
 8048305:	5b                   	pop    %ebx
 8048306:	81 c3 ef 19 00 00    	add    $0x19ef,%ebx
 804830c:	8b 83 fc ff ff ff    	mov    -0x4(%ebx),%eax
 8048312:	85 c0                	test   %eax,%eax
 8048314:	74 05                	je     804831b <_init+0x1f>
 8048316:	e8 21 00 00 00       	call   804833c <__gmon_start__@plt>
 804831b:	e8 10 01 00 00       	call   8048430 <frame_dummy>
 8048320:	e8 cb 03 00 00       	call   80486f0 <__do_global_ctors_aux>
 8048325:	83 c4 08             	add    $0x8,%esp
 8048328:	5b                   	pop    %ebx
 8048329:	c3                   	ret    

Disassembly of section .plt:

0804832c <__gmon_start__@plt-0x10>:
 804832c:	ff 35 f8 9c 04 08    	pushl  0x8049cf8
 8048332:	ff 25 fc 9c 04 08    	jmp    *0x8049cfc
 8048338:	00 00                	add    %al,(%eax)
	...

0804833c <__gmon_start__@plt>:
 804833c:	ff 25 00 9d 04 08    	jmp    *0x8049d00
 8048342:	68 00 00 00 00       	push   $0x0
 8048347:	e9 e0 ff ff ff       	jmp    804832c <_init+0x30>

0804834c <__libc_start_main@plt>:
 804834c:	ff 25 04 9d 04 08    	jmp    *0x8049d04
 8048352:	68 08 00 00 00       	push   $0x8
 8048357:	e9 d0 ff ff ff       	jmp    804832c <_init+0x30>

0804835c <printf@plt>:
 804835c:	ff 25 08 9d 04 08    	jmp    *0x8049d08
 8048362:	68 10 00 00 00       	push   $0x10
 8048367:	e9 c0 ff ff ff       	jmp    804832c <_init+0x30>

0804836c <puts@plt>:
 804836c:	ff 25 0c 9d 04 08    	jmp    *0x8049d0c
 8048372:	68 18 00 00 00       	push   $0x18
 8048377:	e9 b0 ff ff ff       	jmp    804832c <_init+0x30>

Disassembly of section .text:

08048380 <main>:
 8048380:	8d 4c 24 04          	lea    0x4(%esp),%ecx
 8048384:	83 e4 f0             	and    $0xfffffff0,%esp
 8048387:	ff 71 fc             	pushl  -0x4(%ecx)
 804838a:	55                   	push   %ebp
 804838b:	89 e5                	mov    %esp,%ebp
 804838d:	51                   	push   %ecx
 804838e:	50                   	push   %eax
 804838f:	e8 94 01 00 00       	call   8048528 <switch_helper>
 8048394:	e8 1c 02 00 00       	call   80485b5 <func_helper>
 8048399:	e8 99 02 00 00       	call   8048637 <goto_helper>
 804839e:	31 c0                	xor    %eax,%eax
 80483a0:	5a                   	pop    %edx
 80483a1:	59                   	pop    %ecx
 80483a2:	5d                   	pop    %ebp
 80483a3:	8d 61 fc             	lea    -0x4(%ecx),%esp
 80483a6:	c3                   	ret    
 80483a7:	90                   	nop

080483a8 <_start>:
 80483a8:	31 ed                	xor    %ebp,%ebp
 80483aa:	5e                   	pop    %esi
 80483ab:	89 e1                	mov    %esp,%ecx
 80483ad:	83 e4 f0             	and    $0xfffffff0,%esp
 80483b0:	50                   	push   %eax
 80483b1:	54                   	push   %esp
 80483b2:	52                   	push   %edx
 80483b3:	68 e0 86 04 08       	push   $0x80486e0
 80483b8:	68 70 86 04 08       	push   $0x8048670
 80483bd:	51                   	push   %ecx
 80483be:	56                   	push   %esi
 80483bf:	68 80 83 04 08       	push   $0x8048380
 80483c4:	e8 83 ff ff ff       	call   804834c <__libc_start_main@plt>
 80483c9:	f4                   	hlt    
 80483ca:	90                   	nop
 80483cb:	90                   	nop
 80483cc:	90                   	nop
 80483cd:	90                   	nop
 80483ce:	90                   	nop
 80483cf:	90                   	nop

080483d0 <__do_global_dtors_aux>:
 80483d0:	55                   	push   %ebp
 80483d1:	89 e5                	mov    %esp,%ebp
 80483d3:	53                   	push   %ebx
 80483d4:	83 ec 04             	sub    $0x4,%esp
 80483d7:	80 3d 18 9d 04 08 00 	cmpb   $0x0,0x8049d18
 80483de:	75 3f                	jne    804841f <__do_global_dtors_aux+0x4f>
 80483e0:	a1 1c 9d 04 08       	mov    0x8049d1c,%eax
 80483e5:	bb 18 9c 04 08       	mov    $0x8049c18,%ebx
 80483ea:	81 eb 14 9c 04 08    	sub    $0x8049c14,%ebx
 80483f0:	c1 fb 02             	sar    $0x2,%ebx
 80483f3:	83 eb 01             	sub    $0x1,%ebx
 80483f6:	39 d8                	cmp    %ebx,%eax
 80483f8:	73 1e                	jae    8048418 <__do_global_dtors_aux+0x48>
 80483fa:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
 8048400:	83 c0 01             	add    $0x1,%eax
 8048403:	a3 1c 9d 04 08       	mov    %eax,0x8049d1c
 8048408:	ff 14 85 14 9c 04 08 	call   *0x8049c14(,%eax,4)
 804840f:	a1 1c 9d 04 08       	mov    0x8049d1c,%eax
 8048414:	39 d8                	cmp    %ebx,%eax
 8048416:	72 e8                	jb     8048400 <__do_global_dtors_aux+0x30>
 8048418:	c6 05 18 9d 04 08 01 	movb   $0x1,0x8049d18
 804841f:	83 c4 04             	add    $0x4,%esp
 8048422:	5b                   	pop    %ebx
 8048423:	5d                   	pop    %ebp
 8048424:	c3                   	ret    
 8048425:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
 8048429:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

08048430 <frame_dummy>:
 8048430:	55                   	push   %ebp
 8048431:	89 e5                	mov    %esp,%ebp
 8048433:	83 ec 18             	sub    $0x18,%esp
 8048436:	a1 1c 9c 04 08       	mov    0x8049c1c,%eax
 804843b:	85 c0                	test   %eax,%eax
 804843d:	74 12                	je     8048451 <frame_dummy+0x21>
 804843f:	b8 00 00 00 00       	mov    $0x0,%eax
 8048444:	85 c0                	test   %eax,%eax
 8048446:	74 09                	je     8048451 <frame_dummy+0x21>
 8048448:	c7 04 24 1c 9c 04 08 	movl   $0x8049c1c,(%esp)
 804844f:	ff d0                	call   *%eax
 8048451:	c9                   	leave  
 8048452:	c3                   	ret    
 8048453:	90                   	nop

08048454 <sub>:
 8048454:	55                   	push   %ebp
 8048455:	89 e5                	mov    %esp,%ebp
 8048457:	8b 45 08             	mov    0x8(%ebp),%eax
 804845a:	2b 45 0c             	sub    0xc(%ebp),%eax
 804845d:	5d                   	pop    %ebp
 804845e:	c3                   	ret    

0804845f <mul>:
 804845f:	55                   	push   %ebp
 8048460:	89 e5                	mov    %esp,%ebp
 8048462:	8b 45 0c             	mov    0xc(%ebp),%eax
 8048465:	0f af 45 08          	imul   0x8(%ebp),%eax
 8048469:	5d                   	pop    %ebp
 804846a:	c3                   	ret    

0804846b <div>:
 804846b:	55                   	push   %ebp
 804846c:	89 e5                	mov    %esp,%ebp
 804846e:	8b 45 08             	mov    0x8(%ebp),%eax
 8048471:	99                   	cltd   
 8048472:	f7 7d 0c             	idivl  0xc(%ebp)
 8048475:	5d                   	pop    %ebp
 8048476:	c3                   	ret    

08048477 <print_func.1740>:
 8048477:	55                   	push   %ebp
 8048478:	89 e5                	mov    %esp,%ebp
 804847a:	57                   	push   %edi
 804847b:	89 cf                	mov    %ecx,%edi
 804847d:	56                   	push   %esi
 804847e:	89 d6                	mov    %edx,%esi
 8048480:	53                   	push   %ebx
 8048481:	89 c3                	mov    %eax,%ebx
 8048483:	83 ec 14             	sub    $0x14,%esp
 8048486:	51                   	push   %ecx
 8048487:	52                   	push   %edx
 8048488:	ff 14 85 50 88 04 08 	call   *0x8048850(,%eax,4)
 804848f:	89 04 24             	mov    %eax,(%esp)
 8048492:	57                   	push   %edi
 8048493:	56                   	push   %esi
 8048494:	53                   	push   %ebx
 8048495:	68 40 87 04 08       	push   $0x8048740
 804849a:	e8 bd fe ff ff       	call   804835c <printf@plt>
 804849f:	83 c4 20             	add    $0x20,%esp
 80484a2:	8d 65 f4             	lea    -0xc(%ebp),%esp
 80484a5:	5b                   	pop    %ebx
 80484a6:	5e                   	pop    %esi
 80484a7:	5f                   	pop    %edi
 80484a8:	5d                   	pop    %ebp
 80484a9:	c3                   	ret    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Optimizations: just some general instruction reconciliation

;int switch_dispatch(int op, int x, int y)
080484aa <switch_dispatch>:
 80484aa:	55                   	push   %ebp ; save frame pointer
 80484ab:	89 e5                	mov    %esp,%ebp ; update frame pointer
 80484ad:	83 ec 08             	sub    $0x8,%esp ; allocate local storage
 80484b0:	8b 55 08             	mov    0x8(%ebp),%edx ; %edx = op
 80484b3:	8b 45 0c             	mov    0xc(%ebp),%eax ; %eax = x
 80484b6:	8b 4d 10             	mov    0x10(%ebp),%ecx ; %ecx = y
 80484b9:	83 fa 14             	cmp    $0x14,%edx ; compare op and 20
 80484bc:	77 33                	ja     80484f1 <switch_dispatch+0x47> ; jump to error if above
 80484be:	ff 24 95 fc 87 04 08 	jmp    *0x80487fc(,%edx,4) ; otherwise jump to the address indexed in the jump table @ 0x80487fc
 80484c5:	01 c8                	add    %ecx,%eax ; %eax = x + y
 80484c7:	eb 2b                	jmp    80484f4 <switch_dispatch+0x4a> ; done
 80484c9:	0f af c1             	imul   %ecx,%eax ; %eax = x * y
 80484cc:	eb 26                	jmp    80484f4 <switch_dispatch+0x4a> ; done
 80484ce:	99                   	cltd   ; prepare %edx:%eax for division 
 80484cf:	f7 f9                	idiv   %ecx ; %eax = quotient of %edx:%eax / %ecx
 80484d1:	eb 21                	jmp    80484f4 <switch_dispatch+0x4a> ; done
 80484d3:	29 c8                	sub    %ecx,%eax ; %eax = x - y
 80484d5:	eb 1d                	jmp    80484f4 <switch_dispatch+0x4a> ; done
 80484d7:	83 ec 0c             	sub    $0xc,%esp ; allocate 12 bytes for stack alignment
 80484da:	68 5b 87 04 08       	push   $0x804875b ; load string address on stack
 80484df:	eb 08                	jmp    80484e9 <switch_dispatch+0x3f> ; 0x80484e9
 80484e1:	83 ec 0c             	sub    $0xc,%esp ; allocate 12 bytes for stack alignment
 80484e4:	68 90 87 04 08       	push   $0x8048790 ; load string address on stack
 80484e9:	e8 7e fe ff ff       	call   804836c <puts@plt> ; call glibc puts
 80484ee:	83 c4 10             	add    $0x10,%esp ; clean up stack (16 bytes)
 80484f1:	83 c8 ff             	or     $0xffffffff,%eax ; put -1 return value in %eax
 80484f4:	c9                   	leave  ; all branches eventually reach here
 80484f5:	c3                   	ret    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

080484f6 <print_sw.1708>:
 80484f6:	55                   	push   %ebp
 80484f7:	89 e5                	mov    %esp,%ebp
 80484f9:	57                   	push   %edi
 80484fa:	89 cf                	mov    %ecx,%edi
 80484fc:	56                   	push   %esi
 80484fd:	89 d6                	mov    %edx,%esi
 80484ff:	53                   	push   %ebx
 8048500:	89 c3                	mov    %eax,%ebx
 8048502:	83 ec 10             	sub    $0x10,%esp
 8048505:	51                   	push   %ecx
 8048506:	52                   	push   %edx
 8048507:	50                   	push   %eax
 8048508:	e8 9d ff ff ff       	call   80484aa <switch_dispatch>
 804850d:	89 04 24             	mov    %eax,(%esp)
 8048510:	57                   	push   %edi
 8048511:	56                   	push   %esi
 8048512:	53                   	push   %ebx
 8048513:	68 c6 87 04 08       	push   $0x80487c6
 8048518:	e8 3f fe ff ff       	call   804835c <printf@plt>
 804851d:	83 c4 20             	add    $0x20,%esp
 8048520:	8d 65 f4             	lea    -0xc(%ebp),%esp
 8048523:	5b                   	pop    %ebx
 8048524:	5e                   	pop    %esi
 8048525:	5f                   	pop    %edi
 8048526:	5d                   	pop    %ebp
 8048527:	c3                   	ret    

08048528 <switch_helper>:
 8048528:	55                   	push   %ebp
 8048529:	b9 05 00 00 00       	mov    $0x5,%ecx
 804852e:	89 e5                	mov    %esp,%ebp
 8048530:	ba 04 00 00 00       	mov    $0x4,%edx
 8048535:	83 ec 08             	sub    $0x8,%esp
 8048538:	31 c0                	xor    %eax,%eax
 804853a:	e8 b7 ff ff ff       	call   80484f6 <print_sw.1708>
 804853f:	b9 02 00 00 00       	mov    $0x2,%ecx
 8048544:	ba 08 00 00 00       	mov    $0x8,%edx
 8048549:	b8 03 00 00 00       	mov    $0x3,%eax
 804854e:	e8 a3 ff ff ff       	call   80484f6 <print_sw.1708>
 8048553:	51                   	push   %ecx
 8048554:	6a 00                	push   $0x0
 8048556:	6a 00                	push   $0x0
 8048558:	6a 07                	push   $0x7
 804855a:	e8 4b ff ff ff       	call   80484aa <switch_dispatch>
 804855f:	83 c4 0c             	add    $0xc,%esp
 8048562:	6a 00                	push   $0x0
 8048564:	6a 00                	push   $0x0
 8048566:	6a 0a                	push   $0xa
 8048568:	e8 3d ff ff ff       	call   80484aa <switch_dispatch>
 804856d:	83 c4 0c             	add    $0xc,%esp
 8048570:	6a 00                	push   $0x0
 8048572:	6a 00                	push   $0x0
 8048574:	6a 0f                	push   $0xf
 8048576:	e8 2f ff ff ff       	call   80484aa <switch_dispatch>
 804857b:	83 c4 0c             	add    $0xc,%esp
 804857e:	6a 00                	push   $0x0
 8048580:	6a 00                	push   $0x0
 8048582:	6a 14                	push   $0x14
 8048584:	e8 21 ff ff ff       	call   80484aa <switch_dispatch>
 8048589:	83 c4 10             	add    $0x10,%esp
 804858c:	c9                   	leave  
 804858d:	c3                   	ret    

0804858e <add>:
 804858e:	55                   	push   %ebp ; save %ebp
 804858f:	89 e5                	mov    %esp,%ebp ; update %ebp
 8048591:	8b 45 0c             	mov    0xc(%ebp),%eax ; %eax = y
 8048594:	03 45 08             	add    0x8(%ebp),%eax ; %eax = x + y
 8048597:	5d                   	pop    %ebp ; restore %ebp
 8048598:	c3                   	ret    ; return directly to caller of func_dispatch!

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This is an interesting one. Instead of loading the stack with arguments that
; would eventually be unloaded by the appropriate function, func_dispatch only
; rearranges the arguments on the stack before transferring control to the 
; operation handler. %esp doesn't change.

08048599 <func_dispatch>:
 8048599:	55                   	push   %ebp ; save %ebp
 804859a:	89 e5                	mov    %esp,%ebp ; update %ebp
 804859c:	8b 45 08             	mov    0x8(%ebp),%eax ; %eax = op
 804859f:	8b 55 0c             	mov    0xc(%ebp),%edx ; %edx = x
 80485a2:	8b 4d 10             	mov    0x10(%ebp),%ecx ; %ecx = y
 80485a5:	8b 04 85 50 88 04 08 	mov    0x8048850(,%eax,4),%eax ; index into jump table, store jump address in %eax
 80485ac:	89 55 08             	mov    %edx,0x8(%ebp) ; first arg = x
 80485af:	89 4d 0c             	mov    %ecx,0xc(%ebp) ; second arg = y
 80485b2:	5d                   	pop    %ebp ; restore %ebp
 80485b3:	ff e0                	jmp    *%eax ; pass control to [%eax], don't save %eip!

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

080485b5 <func_helper>:
 80485b5:	55                   	push   %ebp
 80485b6:	b9 05 00 00 00       	mov    $0x5,%ecx
 80485bb:	89 e5                	mov    %esp,%ebp
 80485bd:	ba 04 00 00 00       	mov    $0x4,%edx
 80485c2:	83 ec 08             	sub    $0x8,%esp
 80485c5:	31 c0                	xor    %eax,%eax
 80485c7:	e8 ab fe ff ff       	call   8048477 <print_func.1740>
 80485cc:	b9 02 00 00 00       	mov    $0x2,%ecx
 80485d1:	ba 08 00 00 00       	mov    $0x8,%edx
 80485d6:	b8 03 00 00 00       	mov    $0x3,%eax
 80485db:	e8 97 fe ff ff       	call   8048477 <print_func.1740>
 80485e0:	c9                   	leave  
 80485e1:	c3                   	ret    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; With -Os optimization, goto_dispatch reconciles all the data transfer
; of passed arguments from stack to registers to the beginning of the
; subroutine. And a bit smarter about which registers to use for arguments.

080485e2 <goto_dispatch>:
 80485e2:	55                   	push   %ebp ; save %ebp
 80485e3:	89 e5                	mov    %esp,%ebp ; update %ebp
 80485e5:	8b 55 08             	mov    0x8(%ebp),%edx ; %edx = op
 80485e8:	8b 45 0c             	mov    0xc(%ebp),%eax ; %eax = x
 80485eb:	8b 4d 10             	mov    0x10(%ebp),%ecx ; %ecx = y
 80485ee:	ff 24 95 60 88 04 08 	jmp    *0x8048860(,%edx,4) ; index into jump table
 80485f5:	01 c8                	add    %ecx,%eax ; %eax = x + y
 80485f7:	eb 0c                	jmp    8048605 <goto_dispatch+0x23> ; done
 80485f9:	29 c8                	sub    %ecx,%eax ; %eax = x - y
 80485fb:	eb 08                	jmp    8048605 <goto_dispatch+0x23> ; done
 80485fd:	0f af c1             	imul   %ecx,%eax ; %eax = x * y
 8048600:	eb 03                	jmp    8048605 <goto_dispatch+0x23> ; done
 8048602:	99                   	cltd   ; prepare %edx:%eax
 8048603:	f7 f9                	idiv   %ecx ; %eax = quotient of %edx:%eax / %ecx
 8048605:	5d                   	pop    %ebp ; restore %ebp
 8048606:	c3                   	ret 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

08048607 <print_goto.1758>:
 8048607:	55                   	push   %ebp
 8048608:	89 e5                	mov    %esp,%ebp
 804860a:	57                   	push   %edi
 804860b:	89 cf                	mov    %ecx,%edi
 804860d:	56                   	push   %esi
 804860e:	89 d6                	mov    %edx,%esi
 8048610:	53                   	push   %ebx
 8048611:	89 c3                	mov    %eax,%ebx
 8048613:	83 ec 0c             	sub    $0xc,%esp
 8048616:	51                   	push   %ecx
 8048617:	52                   	push   %edx
 8048618:	50                   	push   %eax
 8048619:	e8 c4 ff ff ff       	call   80485e2 <goto_dispatch>
 804861e:	50                   	push   %eax
 804861f:	57                   	push   %edi
 8048620:	56                   	push   %esi
 8048621:	53                   	push   %ebx
 8048622:	68 e1 87 04 08       	push   $0x80487e1
 8048627:	e8 30 fd ff ff       	call   804835c <printf@plt>
 804862c:	83 c4 20             	add    $0x20,%esp
 804862f:	8d 65 f4             	lea    -0xc(%ebp),%esp
 8048632:	5b                   	pop    %ebx
 8048633:	5e                   	pop    %esi
 8048634:	5f                   	pop    %edi
 8048635:	5d                   	pop    %ebp
 8048636:	c3                   	ret    

08048637 <goto_helper>:
 8048637:	55                   	push   %ebp
 8048638:	b9 05 00 00 00       	mov    $0x5,%ecx
 804863d:	89 e5                	mov    %esp,%ebp
 804863f:	ba 04 00 00 00       	mov    $0x4,%edx
 8048644:	83 ec 08             	sub    $0x8,%esp
 8048647:	31 c0                	xor    %eax,%eax
 8048649:	e8 b9 ff ff ff       	call   8048607 <print_goto.1758>
 804864e:	b9 02 00 00 00       	mov    $0x2,%ecx
 8048653:	ba 08 00 00 00       	mov    $0x8,%edx
 8048658:	b8 03 00 00 00       	mov    $0x3,%eax
 804865d:	e8 a5 ff ff ff       	call   8048607 <print_goto.1758>
 8048662:	c9                   	leave  
 8048663:	c3                   	ret    
 8048664:	90                   	nop
 8048665:	90                   	nop
 8048666:	90                   	nop
 8048667:	90                   	nop
 8048668:	90                   	nop
 8048669:	90                   	nop
 804866a:	90                   	nop
 804866b:	90                   	nop
 804866c:	90                   	nop
 804866d:	90                   	nop
 804866e:	90                   	nop
 804866f:	90                   	nop

08048670 <__libc_csu_init>:
 8048670:	55                   	push   %ebp
 8048671:	57                   	push   %edi
 8048672:	56                   	push   %esi
 8048673:	53                   	push   %ebx
 8048674:	e8 69 00 00 00       	call   80486e2 <__i686.get_pc_thunk.bx>
 8048679:	81 c3 7b 16 00 00    	add    $0x167b,%ebx
 804867f:	83 ec 1c             	sub    $0x1c,%esp
 8048682:	8b 6c 24 30          	mov    0x30(%esp),%ebp
 8048686:	8d bb 18 ff ff ff    	lea    -0xe8(%ebx),%edi
 804868c:	e8 6b fc ff ff       	call   80482fc <_init>
 8048691:	8d 83 18 ff ff ff    	lea    -0xe8(%ebx),%eax
 8048697:	29 c7                	sub    %eax,%edi
 8048699:	c1 ff 02             	sar    $0x2,%edi
 804869c:	85 ff                	test   %edi,%edi
 804869e:	74 29                	je     80486c9 <__libc_csu_init+0x59>
 80486a0:	31 f6                	xor    %esi,%esi
 80486a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
 80486a8:	8b 44 24 38          	mov    0x38(%esp),%eax
 80486ac:	89 2c 24             	mov    %ebp,(%esp)
 80486af:	89 44 24 08          	mov    %eax,0x8(%esp)
 80486b3:	8b 44 24 34          	mov    0x34(%esp),%eax
 80486b7:	89 44 24 04          	mov    %eax,0x4(%esp)
 80486bb:	ff 94 b3 18 ff ff ff 	call   *-0xe8(%ebx,%esi,4)
 80486c2:	83 c6 01             	add    $0x1,%esi
 80486c5:	39 fe                	cmp    %edi,%esi
 80486c7:	75 df                	jne    80486a8 <__libc_csu_init+0x38>
 80486c9:	83 c4 1c             	add    $0x1c,%esp
 80486cc:	5b                   	pop    %ebx
 80486cd:	5e                   	pop    %esi
 80486ce:	5f                   	pop    %edi
 80486cf:	5d                   	pop    %ebp
 80486d0:	c3                   	ret    
 80486d1:	eb 0d                	jmp    80486e0 <__libc_csu_fini>
 80486d3:	90                   	nop
 80486d4:	90                   	nop
 80486d5:	90                   	nop
 80486d6:	90                   	nop
 80486d7:	90                   	nop
 80486d8:	90                   	nop
 80486d9:	90                   	nop
 80486da:	90                   	nop
 80486db:	90                   	nop
 80486dc:	90                   	nop
 80486dd:	90                   	nop
 80486de:	90                   	nop
 80486df:	90                   	nop

080486e0 <__libc_csu_fini>:
 80486e0:	f3 c3                	repz ret 

080486e2 <__i686.get_pc_thunk.bx>:
 80486e2:	8b 1c 24             	mov    (%esp),%ebx
 80486e5:	c3                   	ret    
 80486e6:	90                   	nop
 80486e7:	90                   	nop
 80486e8:	90                   	nop
 80486e9:	90                   	nop
 80486ea:	90                   	nop
 80486eb:	90                   	nop
 80486ec:	90                   	nop
 80486ed:	90                   	nop
 80486ee:	90                   	nop
 80486ef:	90                   	nop

080486f0 <__do_global_ctors_aux>:
 80486f0:	55                   	push   %ebp
 80486f1:	89 e5                	mov    %esp,%ebp
 80486f3:	53                   	push   %ebx
 80486f4:	83 ec 04             	sub    $0x4,%esp
 80486f7:	a1 0c 9c 04 08       	mov    0x8049c0c,%eax
 80486fc:	83 f8 ff             	cmp    $0xffffffff,%eax
 80486ff:	74 13                	je     8048714 <__do_global_ctors_aux+0x24>
 8048701:	bb 0c 9c 04 08       	mov    $0x8049c0c,%ebx
 8048706:	66 90                	xchg   %ax,%ax
 8048708:	83 eb 04             	sub    $0x4,%ebx
 804870b:	ff d0                	call   *%eax
 804870d:	8b 03                	mov    (%ebx),%eax
 804870f:	83 f8 ff             	cmp    $0xffffffff,%eax
 8048712:	75 f4                	jne    8048708 <__do_global_ctors_aux+0x18>
 8048714:	83 c4 04             	add    $0x4,%esp
 8048717:	5b                   	pop    %ebx
 8048718:	5d                   	pop    %ebp
 8048719:	c3                   	ret    
 804871a:	90                   	nop
 804871b:	90                   	nop

Disassembly of section .fini:

0804871c <_fini>:
 804871c:	53                   	push   %ebx
 804871d:	83 ec 08             	sub    $0x8,%esp
 8048720:	e8 00 00 00 00       	call   8048725 <_fini+0x9>
 8048725:	5b                   	pop    %ebx
 8048726:	81 c3 cf 15 00 00    	add    $0x15cf,%ebx
 804872c:	e8 9f fc ff ff       	call   80483d0 <__do_global_dtors_aux>
 8048731:	83 c4 08             	add    $0x8,%esp
 8048734:	5b                   	pop    %ebx
 8048735:	c3                   	ret    

Disassembly of section .rodata:

08048738 <_fp_hw>:
 8048738:	03 00                	add    (%eax),%eax
	...

0804873c <_IO_stdin_used>:
 804873c:	01 00                	add    %eax,(%eax)
 804873e:	02 00                	add    (%eax),%al
 8048740:	46                   	inc    %esi
 8048741:	55                   	push   %ebp
 8048742:	4e                   	dec    %esi
 8048743:	43                   	inc    %ebx
 8048744:	3a 20                	cmp    (%eax),%ah
 8048746:	6f                   	outsl  %ds:(%esi),(%dx)
 8048747:	70 20                	jo     8048769 <_IO_stdin_used+0x2d>
 8048749:	25 64 20 28 25       	and    $0x25282064,%eax
 804874e:	64                   	fs
 804874f:	2c 20                	sub    $0x20,%al
 8048751:	25 64 29 20 3d       	and    $0x3d202964,%eax
 8048756:	20 25 64 0a 00 73    	and    %ah,0x73000a64
 804875c:	77 69                	ja     80487c7 <_IO_stdin_used+0x8b>
 804875e:	74 63                	je     80487c3 <_IO_stdin_used+0x87>
 8048760:	68 5f 64 69 73       	push   $0x7369645f
 8048765:	70 61                	jo     80487c8 <_IO_stdin_used+0x8c>
 8048767:	74 63                	je     80487cc <_IO_stdin_used+0x90>
 8048769:	68 20 69 6e 76       	push   $0x766e6920
 804876e:	6f                   	outsl  %ds:(%esi),(%dx)
 804876f:	6b 65 64 20          	imul   $0x20,0x64(%ebp),%esp
 8048773:	77 69                	ja     80487de <_IO_stdin_used+0xa2>
 8048775:	74 68                	je     80487df <_IO_stdin_used+0xa3>
 8048777:	20 6f 70             	and    %ch,0x70(%edi)
 804877a:	63 6f 64             	arpl   %bp,0x64(%edi)
 804877d:	65 20 69 6e          	and    %ch,%gs:0x6e(%ecx)
 8048781:	20 72 61             	and    %dh,0x61(%edx)
 8048784:	6e                   	outsb  %ds:(%esi),(%dx)
 8048785:	67 65 20 37          	and    %dh,%gs:(%bx)
 8048789:	20 74 6f 20          	and    %dh,0x20(%edi,%ebp,2)
 804878d:	31 30                	xor    %esi,(%eax)
 804878f:	00 73 77             	add    %dh,0x77(%ebx)
 8048792:	69 74 63 68 5f 64 69 	imul   $0x7369645f,0x68(%ebx,%eiz,2),%esi
 8048799:	73 
 804879a:	70 61                	jo     80487fd <_IO_stdin_used+0xc1>
 804879c:	74 63                	je     8048801 <_IO_stdin_used+0xc5>
 804879e:	68 20 69 6e 76       	push   $0x766e6920
 80487a3:	6f                   	outsl  %ds:(%esi),(%dx)
 80487a4:	6b 65 64 20          	imul   $0x20,0x64(%ebp),%esp
 80487a8:	77 69                	ja     8048813 <_IO_stdin_used+0xd7>
 80487aa:	74 68                	je     8048814 <_IO_stdin_used+0xd8>
 80487ac:	20 6f 70             	and    %ch,0x70(%edi)
 80487af:	63 6f 64             	arpl   %bp,0x64(%edi)
 80487b2:	65 20 69 6e          	and    %ch,%gs:0x6e(%ecx)
 80487b6:	20 72 61             	and    %dh,0x61(%edx)
 80487b9:	6e                   	outsb  %ds:(%esi),(%dx)
 80487ba:	67 65 20 31          	and    %dh,%gs:(%bx,%di)
 80487be:	35 20 74 6f 20       	xor    $0x206f7420,%eax
 80487c3:	32 30                	xor    (%eax),%dh
 80487c5:	00 53 57             	add    %dl,0x57(%ebx)
 80487c8:	43                   	inc    %ebx
 80487c9:	48                   	dec    %eax
 80487ca:	3a 20                	cmp    (%eax),%ah
 80487cc:	6f                   	outsl  %ds:(%esi),(%dx)
 80487cd:	70 20                	jo     80487ef <_IO_stdin_used+0xb3>
 80487cf:	25 64 20 28 25       	and    $0x25282064,%eax
 80487d4:	64                   	fs
 80487d5:	2c 20                	sub    $0x20,%al
 80487d7:	25 64 29 20 3d       	and    $0x3d202964,%eax
 80487dc:	20 25 64 0a 00 47    	and    %ah,0x47000a64
 80487e2:	4f                   	dec    %edi
 80487e3:	54                   	push   %esp
 80487e4:	4f                   	dec    %edi
 80487e5:	3a 20                	cmp    (%eax),%ah
 80487e7:	6f                   	outsl  %ds:(%esi),(%dx)
 80487e8:	70 20                	jo     804880a <_IO_stdin_used+0xce>
 80487ea:	25 64 20 28 25       	and    $0x25282064,%eax
 80487ef:	64                   	fs
 80487f0:	2c 20                	sub    $0x20,%al
 80487f2:	25 64 29 20 3d       	and    $0x3d202964,%eax
 80487f7:	20 25 64 0a 00 c5    	and    %ah,0xc5000a64
        ; jump table for switch_dispatch starts here
 80487fd:	84 04 08             	test   %al,(%eax,%ecx,1)
 8048800:	d3 84 04 08 c9 84 04 	roll   %cl,0x484c908(%esp,%eax,1)
 8048807:	08 ce                	or     %cl,%dh
 8048809:	84 04 08             	test   %al,(%eax,%ecx,1)
 804880c:	f1                   	icebp  
 804880d:	84 04 08             	test   %al,(%eax,%ecx,1)
 8048810:	f1                   	icebp  
 8048811:	84 04 08             	test   %al,(%eax,%ecx,1)
 8048814:	f1                   	icebp  
 8048815:	84 04 08             	test   %al,(%eax,%ecx,1)
 8048818:	d7                   	xlat   %ds:(%ebx)
 8048819:	84 04 08             	test   %al,(%eax,%ecx,1)
 804881c:	d7                   	xlat   %ds:(%ebx)
 804881d:	84 04 08             	test   %al,(%eax,%ecx,1)
 8048820:	d7                   	xlat   %ds:(%ebx)
 8048821:	84 04 08             	test   %al,(%eax,%ecx,1)
 8048824:	d7                   	xlat   %ds:(%ebx)
 8048825:	84 04 08             	test   %al,(%eax,%ecx,1)
 8048828:	f1                   	icebp  
 8048829:	84 04 08             	test   %al,(%eax,%ecx,1)
 804882c:	f1                   	icebp  
 804882d:	84 04 08             	test   %al,(%eax,%ecx,1)
 8048830:	f1                   	icebp  
 8048831:	84 04 08             	test   %al,(%eax,%ecx,1)
 8048834:	f1                   	icebp  
 8048835:	84 04 08             	test   %al,(%eax,%ecx,1)
 8048838:	e1 84                	loope  80487be <_IO_stdin_used+0x82>
 804883a:	04 08                	add    $0x8,%al
 804883c:	e1 84                	loope  80487c2 <_IO_stdin_used+0x86>
 804883e:	04 08                	add    $0x8,%al
 8048840:	e1 84                	loope  80487c6 <_IO_stdin_used+0x8a>
 8048842:	04 08                	add    $0x8,%al
 8048844:	e1 84                	loope  80487ca <_IO_stdin_used+0x8e>
 8048846:	04 08                	add    $0x8,%al
 8048848:	e1 84                	loope  80487ce <_IO_stdin_used+0x92>
 804884a:	04 08                	add    $0x8,%al
 804884c:	e1 84                	loope  80487d2 <_IO_stdin_used+0x96>
 804884e:	04 08                	add    $0x8,%al

08048850 <jumptable.1733>:
 8048850:	00 00                	add    %al,(%eax)
 8048852:	00 00                	add    %al,(%eax)
 8048854:	54                   	push   %esp
 8048855:	84 04 08             	test   %al,(%eax,%ecx,1)
 8048858:	5f                   	pop    %edi
 8048859:	84 04 08             	test   %al,(%eax,%ecx,1)
 804885c:	6b 84 04 08 f5 85 04 	imul   $0x8,0x485f508(%esp,%eax,1),%eax
 8048863:	08 

08048860 <labeltable.1747>:
 8048860:	f5                   	cmc    
 8048861:	85 04 08             	test   %eax,(%eax,%ecx,1)
 8048864:	f9                   	stc    
 8048865:	85 04 08             	test   %eax,(%eax,%ecx,1)
 8048868:	fd                   	std    
 8048869:	85 04 08             	test   %eax,(%eax,%ecx,1)
 804886c:	02                   	.byte 0x2
 804886d:	86 04 08             	xchg   %al,(%eax,%ecx,1)

Disassembly of section .eh_frame_hdr:

08048870 <.eh_frame_hdr>:
 8048870:	01 1b                	add    %ebx,(%ebx)
 8048872:	03 3b                	add    (%ebx),%edi
 8048874:	90                   	nop
 8048875:	00 00                	add    %al,(%eax)
 8048877:	00 11                	add    %dl,(%ecx)
 8048879:	00 00                	add    %al,(%eax)
 804887b:	00 10                	add    %dl,(%eax)
 804887d:	fb                   	sti    
 804887e:	ff                   	(bad)  
 804887f:	ff 08                	decl   (%eax)
 8048881:	03 00                	add    (%eax),%eax
 8048883:	00 e4                	add    %ah,%ah
 8048885:	fb                   	sti    
 8048886:	ff                   	(bad)  
 8048887:	ff ac 00 00 00 ef fb 	ljmp   *-0x4110000(%eax,%eax,1)
 804888e:	ff                   	(bad)  
 804888f:	ff cc                	dec    %esp
 8048891:	00 00                	add    %al,(%eax)
 8048893:	00 fb                	add    %bh,%bl
 8048895:	fb                   	sti    
 8048896:	ff                   	(bad)  
 8048897:	ff ec                	ljmp   *<internal disassembler error>
 8048899:	00 00                	add    %al,(%eax)
 804889b:	00 07                	add    %al,(%edi)
 804889d:	fc                   	cld    
 804889e:	ff                   	(bad)  
 804889f:	ff 0c 01             	decl   (%ecx,%eax,1)
 80488a2:	00 00                	add    %al,(%eax)
 80488a4:	3a fc                	cmp    %ah,%bh
 80488a6:	ff                   	(bad)  
 80488a7:	ff 54 01 00          	call   *0x0(%ecx,%eax,1)
 80488ab:	00 86 fc ff ff 84    	add    %al,-0x7b000004(%esi)
 80488b1:	01 00                	add    %eax,(%eax)
 80488b3:	00 b8 fc ff ff cc    	add    %bh,-0x33000004(%eax)
 80488b9:	01 00                	add    %eax,(%eax)
 80488bb:	00 1e                	add    %bl,(%esi)
 80488bd:	fd                   	std    
 80488be:	ff                   	(bad)  
 80488bf:	ff 20                	jmp    *(%eax)
 80488c1:	02 00                	add    (%eax),%al
 80488c3:	00 29                	add    %ch,(%ecx)
 80488c5:	fd                   	std    
 80488c6:	ff                   	(bad)  
 80488c7:	ff 40 02             	incl   0x2(%eax)
 80488ca:	00 00                	add    %al,(%eax)
 80488cc:	45                   	inc    %ebp
 80488cd:	fd                   	std    
 80488ce:	ff                   	(bad)  
 80488cf:	ff 60 02             	jmp    *0x2(%eax)
 80488d2:	00 00                	add    %al,(%eax)
 80488d4:	72 fd                	jb     80488d3 <labeltable.1747+0x73>
 80488d6:	ff                   	(bad)  
 80488d7:	ff 80 02 00 00 97    	incl   -0x68fffffe(%eax)
 80488dd:	fd                   	std    
 80488de:	ff                   	(bad)  
 80488df:	ff a0 02 00 00 c7    	jmp    *-0x38fffffe(%eax)
 80488e5:	fd                   	std    
 80488e6:	ff                   	(bad)  
 80488e7:	ff e8                	ljmp   *<internal disassembler error>
 80488e9:	02 00                	add    (%eax),%al
 80488eb:	00 00                	add    %al,(%eax)
 80488ed:	fe                   	(bad)  
 80488ee:	ff                   	(bad)  
 80488ef:	ff 34 03             	pushl  (%ebx,%eax,1)
 80488f2:	00 00                	add    %al,(%eax)
 80488f4:	70 fe                	jo     80488f4 <labeltable.1747+0x94>
 80488f6:	ff                   	(bad)  
 80488f7:	ff 70 03             	pushl  0x3(%eax)
 80488fa:	00 00                	add    %al,(%eax)
 80488fc:	72 fe                	jb     80488fc <labeltable.1747+0x9c>
 80488fe:	ff                   	(bad)  
 80488ff:	ff                   	.byte 0xff
 8048900:	84 03                	test   %al,(%ebx)
	...

Disassembly of section .eh_frame:

08048904 <__FRAME_END__-0x304>:
 8048904:	14 00                	adc    $0x0,%al
 8048906:	00 00                	add    %al,(%eax)
 8048908:	00 00                	add    %al,(%eax)
 804890a:	00 00                	add    %al,(%eax)
 804890c:	01 7a 52             	add    %edi,0x52(%edx)
 804890f:	00 01                	add    %al,(%ecx)
 8048911:	7c 08                	jl     804891b <labeltable.1747+0xbb>
 8048913:	01 1b                	add    %ebx,(%ebx)
 8048915:	0c 04                	or     $0x4,%al
 8048917:	04 88                	add    $0x88,%al
 8048919:	01 00                	add    %eax,(%eax)
 804891b:	00 1c 00             	add    %bl,(%eax,%eax,1)
 804891e:	00 00                	add    %al,(%eax)
 8048920:	1c 00                	sbb    $0x0,%al
 8048922:	00 00                	add    %al,(%eax)
 8048924:	30 fb                	xor    %bh,%bl
 8048926:	ff                   	(bad)  
 8048927:	ff 0b                	decl   (%ebx)
 8048929:	00 00                	add    %al,(%eax)
 804892b:	00 00                	add    %al,(%eax)
 804892d:	41                   	inc    %ecx
 804892e:	0e                   	push   %cs
 804892f:	08 85 02 42 0d 05    	or     %al,0x50d4202(%ebp)
 8048935:	47                   	inc    %edi
 8048936:	0c 04                	or     $0x4,%al
 8048938:	04 c5                	add    $0xc5,%al
 804893a:	00 00                	add    %al,(%eax)
 804893c:	1c 00                	sbb    $0x0,%al
 804893e:	00 00                	add    %al,(%eax)
 8048940:	3c 00                	cmp    $0x0,%al
 8048942:	00 00                	add    %al,(%eax)
 8048944:	1b fb                	sbb    %ebx,%edi
 8048946:	ff                   	(bad)  
 8048947:	ff 0c 00             	decl   (%eax,%eax,1)
 804894a:	00 00                	add    %al,(%eax)
 804894c:	00 41 0e             	add    %al,0xe(%ecx)
 804894f:	08 85 02 42 0d 05    	or     %al,0x50d4202(%ebp)
 8048955:	48                   	dec    %eax
 8048956:	0c 04                	or     $0x4,%al
 8048958:	04 c5                	add    $0xc5,%al
 804895a:	00 00                	add    %al,(%eax)
 804895c:	1c 00                	sbb    $0x0,%al
 804895e:	00 00                	add    %al,(%eax)
 8048960:	5c                   	pop    %esp
 8048961:	00 00                	add    %al,(%eax)
 8048963:	00 07                	add    %al,(%edi)
 8048965:	fb                   	sti    
 8048966:	ff                   	(bad)  
 8048967:	ff 0c 00             	decl   (%eax,%eax,1)
 804896a:	00 00                	add    %al,(%eax)
 804896c:	00 41 0e             	add    %al,0xe(%ecx)
 804896f:	08 85 02 42 0d 05    	or     %al,0x50d4202(%ebp)
 8048975:	48                   	dec    %eax
 8048976:	0c 04                	or     $0x4,%al
 8048978:	04 c5                	add    $0xc5,%al
 804897a:	00 00                	add    %al,(%eax)
 804897c:	44                   	inc    %esp
 804897d:	00 00                	add    %al,(%eax)
 804897f:	00 7c 00 00          	add    %bh,0x0(%eax,%eax,1)
 8048983:	00 f3                	add    %dh,%bl
 8048985:	fa                   	cli    
 8048986:	ff                   	(bad)  
 8048987:	ff 33                	pushl  (%ebx)
 8048989:	00 00                	add    %al,(%eax)
 804898b:	00 00                	add    %al,(%eax)
 804898d:	41                   	inc    %ecx
 804898e:	0e                   	push   %cs
 804898f:	08 85 02 42 0d 05    	or     %al,0x50d4202(%ebp)
 8048995:	43                   	inc    %ebx
 8048996:	87 03                	xchg   %eax,(%ebx)
 8048998:	43                   	inc    %ebx
 8048999:	86 04 43             	xchg   %al,(%ebx,%eax,2)
 804899c:	83 05 43 2e 08 41 2e 	addl   $0x2e,0x41082e43
 80489a3:	0c 41                	or     $0x41,%al
 80489a5:	2e 10 4b 2e          	adc    %cl,%cs:0x2e(%ebx)
 80489a9:	14 41                	adc    $0x41,%al
 80489ab:	2e 18 41 2e          	sbb    %al,%cs:0x2e(%ecx)
 80489af:	1c 45                	sbb    $0x45,%al
 80489b1:	2e 20 48 2e          	and    %cl,%cs:0x2e(%eax)
 80489b5:	00 44 c3 41          	add    %al,0x41(%ebx,%eax,8)
 80489b9:	c6 41 c7 41          	movb   $0x41,-0x39(%ecx)
 80489bd:	0c 04                	or     $0x4,%al
 80489bf:	04 c5                	add    $0xc5,%al
 80489c1:	00 00                	add    %al,(%eax)
 80489c3:	00 2c 00             	add    %ch,(%eax,%eax,1)
 80489c6:	00 00                	add    %al,(%eax)
 80489c8:	c4 00                	les    (%eax),%eax
 80489ca:	00 00                	add    %al,(%eax)
 80489cc:	de fa                	fdivrp %st,%st(2)
 80489ce:	ff                   	(bad)  
 80489cf:	ff 4c 00 00          	decl   0x0(%eax,%eax,1)
 80489d3:	00 00                	add    %al,(%eax)
 80489d5:	41                   	inc    %ecx
 80489d6:	0e                   	push   %cs
 80489d7:	08 85 02 42 0d 05    	or     %al,0x50d4202(%ebp)
 80489dd:	6d                   	insl   (%dx),%es:(%edi)
 80489de:	2e                   	cs
 80489df:	0c 45                	or     $0x45,%al
 80489e1:	2e 10 42 2e          	adc    %al,%cs:0x2e(%edx)
 80489e5:	00 43 2e             	add    %al,0x2e(%ebx)
 80489e8:	0c 45                	or     $0x45,%al
 80489ea:	2e 10 48 2e          	adc    %cl,%cs:0x2e(%eax)
 80489ee:	00 44 c5 0c          	add    %al,0xc(%ebp,%eax,8)
 80489f2:	04 04                	add    $0x4,%al
 80489f4:	44                   	inc    %esp
 80489f5:	00 00                	add    %al,(%eax)
 80489f7:	00 f4                	add    %dh,%ah
 80489f9:	00 00                	add    %al,(%eax)
 80489fb:	00 fa                	add    %bh,%dl
 80489fd:	fa                   	cli    
 80489fe:	ff                   	(bad)  
 80489ff:	ff 32                	pushl  (%edx)
 8048a01:	00 00                	add    %al,(%eax)
 8048a03:	00 00                	add    %al,(%eax)
 8048a05:	41                   	inc    %ecx
 8048a06:	0e                   	push   %cs
 8048a07:	08 85 02 42 0d 05    	or     %al,0x50d4202(%ebp)
 8048a0d:	43                   	inc    %ebx
 8048a0e:	87 03                	xchg   %eax,(%ebx)
 8048a10:	43                   	inc    %ebx
 8048a11:	86 04 43             	xchg   %al,(%ebx,%eax,2)
 8048a14:	83 05 43 2e 04 41 2e 	addl   $0x2e,0x41042e43
 8048a1b:	08 41 2e             	or     %al,0x2e(%ecx)
 8048a1e:	0c 41                	or     $0x41,%al
 8048a20:	2e 10 49 2e          	adc    %cl,%cs:0x2e(%ecx)
 8048a24:	14 41                	adc    $0x41,%al
 8048a26:	2e 18 41 2e          	sbb    %al,%cs:0x2e(%ecx)
 8048a2a:	1c 45                	sbb    $0x45,%al
 8048a2c:	2e 20 48 2e          	and    %cl,%cs:0x2e(%eax)
 8048a30:	00 44 c3 41          	add    %al,0x41(%ebx,%eax,8)
 8048a34:	c6 41 c7 41          	movb   $0x41,-0x39(%ecx)
 8048a38:	0c 04                	or     $0x4,%al
 8048a3a:	04 c5                	add    $0xc5,%al
 8048a3c:	50                   	push   %eax
 8048a3d:	00 00                	add    %al,(%eax)
 8048a3f:	00 3c 01             	add    %bh,(%ecx,%eax,1)
 8048a42:	00 00                	add    %al,(%eax)
 8048a44:	e4 fa                	in     $0xfa,%al
 8048a46:	ff                   	(bad)  
 8048a47:	ff 66 00             	jmp    *0x0(%esi)
 8048a4a:	00 00                	add    %al,(%eax)
 8048a4c:	00 41 0e             	add    %al,0xe(%ecx)
 8048a4f:	08 85 02 47 0d 05    	or     %al,0x50d4702(%ebp)
 8048a55:	64                   	fs
 8048a56:	2e                   	cs
 8048a57:	04 42                	add    $0x42,%al
 8048a59:	2e 08 42 2e          	or     %al,%cs:0x2e(%edx)
 8048a5d:	0c 42                	or     $0x42,%al
 8048a5f:	2e 10 48 2e          	adc    %cl,%cs:0x2e(%eax)
 8048a63:	04 42                	add    $0x42,%al
 8048a65:	2e 08 42 2e          	or     %al,%cs:0x2e(%edx)
 8048a69:	0c 42                	or     $0x42,%al
 8048a6b:	2e 10 48 2e          	adc    %cl,%cs:0x2e(%eax)
 8048a6f:	04 42                	add    $0x42,%al
 8048a71:	2e 08 42 2e          	or     %al,%cs:0x2e(%edx)
 8048a75:	0c 42                	or     $0x42,%al
 8048a77:	2e 10 48 2e          	adc    %cl,%cs:0x2e(%eax)
 8048a7b:	04 42                	add    $0x42,%al
 8048a7d:	2e 08 42 2e          	or     %al,%cs:0x2e(%edx)
 8048a81:	0c 42                	or     $0x42,%al
 8048a83:	2e 10 48 2e          	adc    %cl,%cs:0x2e(%eax)
 8048a87:	00 41 c5             	add    %al,-0x3b(%ecx)
 8048a8a:	0c 04                	or     $0x4,%al
 8048a8c:	04 00                	add    $0x0,%al
 8048a8e:	00 00                	add    %al,(%eax)
 8048a90:	1c 00                	sbb    $0x0,%al
 8048a92:	00 00                	add    %al,(%eax)
 8048a94:	90                   	nop
 8048a95:	01 00                	add    %eax,(%eax)
 8048a97:	00 f6                	add    %dh,%dh
 8048a99:	fa                   	cli    
 8048a9a:	ff                   	(bad)  
 8048a9b:	ff 0b                	decl   (%ebx)
 8048a9d:	00 00                	add    %al,(%eax)
 8048a9f:	00 00                	add    %al,(%eax)
 8048aa1:	41                   	inc    %ecx
 8048aa2:	0e                   	push   %cs
 8048aa3:	08 85 02 42 0d 05    	or     %al,0x50d4202(%ebp)
 8048aa9:	47                   	inc    %edi
 8048aaa:	0c 04                	or     $0x4,%al
 8048aac:	04 c5                	add    $0xc5,%al
 8048aae:	00 00                	add    %al,(%eax)
 8048ab0:	1c 00                	sbb    $0x0,%al
 8048ab2:	00 00                	add    %al,(%eax)
 8048ab4:	b0 01                	mov    $0x1,%al
 8048ab6:	00 00                	add    %al,(%eax)
 8048ab8:	e1 fa                	loope  8048ab4 <labeltable.1747+0x254>
 8048aba:	ff                   	(bad)  
 8048abb:	ff 1c 00             	lcall  *(%eax,%eax,1)
 8048abe:	00 00                	add    %al,(%eax)
 8048ac0:	00 41 0e             	add    %al,0xe(%ecx)
 8048ac3:	08 85 02 42 0d 05    	or     %al,0x50d4202(%ebp)
 8048ac9:	57                   	push   %edi
 8048aca:	0c 04                	or     $0x4,%al
 8048acc:	04 c5                	add    $0xc5,%al
 8048ace:	00 00                	add    %al,(%eax)
 8048ad0:	1c 00                	sbb    $0x0,%al
 8048ad2:	00 00                	add    %al,(%eax)
 8048ad4:	d0 01                	rolb   (%ecx)
 8048ad6:	00 00                	add    %al,(%eax)
 8048ad8:	dd fa                	(bad)  
 8048ada:	ff                   	(bad)  
 8048adb:	ff 2d 00 00 00 00    	ljmp   *0x0
 8048ae1:	41                   	inc    %ecx
 8048ae2:	0e                   	push   %cs
 8048ae3:	08 85 02 47 0d 05    	or     %al,0x50d4702(%ebp)
 8048ae9:	64 c5 0c 04          	lds    %fs:(%esp,%eax,1),%ecx
 8048aed:	04 00                	add    $0x0,%al
 8048aef:	00 1c 00             	add    %bl,(%eax,%eax,1)
 8048af2:	00 00                	add    %al,(%eax)
 8048af4:	f0 01 00             	lock add %eax,(%eax)
 8048af7:	00 ea                	add    %ch,%dl
 8048af9:	fa                   	cli    
 8048afa:	ff                   	(bad)  
 8048afb:	ff 25 00 00 00 00    	jmp    *0x0
 8048b01:	41                   	inc    %ecx
 8048b02:	0e                   	push   %cs
 8048b03:	08 85 02 42 0d 05    	or     %al,0x50d4202(%ebp)
 8048b09:	61                   	popa   
 8048b0a:	0c 04                	or     $0x4,%al
 8048b0c:	04 c5                	add    $0xc5,%al
 8048b0e:	00 00                	add    %al,(%eax)
 8048b10:	44                   	inc    %esp
 8048b11:	00 00                	add    %al,(%eax)
 8048b13:	00 10                	add    %dl,(%eax)
 8048b15:	02 00                	add    (%eax),%al
 8048b17:	00 ef                	add    %ch,%bh
 8048b19:	fa                   	cli    
 8048b1a:	ff                   	(bad)  
 8048b1b:	ff 30                	pushl  (%eax)
 8048b1d:	00 00                	add    %al,(%eax)
 8048b1f:	00 00                	add    %al,(%eax)
 8048b21:	41                   	inc    %ecx
 8048b22:	0e                   	push   %cs
 8048b23:	08 85 02 42 0d 05    	or     %al,0x50d4202(%ebp)
 8048b29:	43                   	inc    %ebx
 8048b2a:	87 03                	xchg   %eax,(%ebx)
 8048b2c:	43                   	inc    %ebx
 8048b2d:	86 04 43             	xchg   %al,(%ebx,%eax,2)
 8048b30:	83 05 44 2e 04 41 2e 	addl   $0x2e,0x41042e44
 8048b37:	08 41 2e             	or     %al,0x2e(%ecx)
 8048b3a:	0c 46                	or     $0x46,%al
 8048b3c:	2e 10 41 2e          	adc    %al,%cs:0x2e(%ecx)
 8048b40:	14 41                	adc    $0x41,%al
 8048b42:	2e 18 41 2e          	sbb    %al,%cs:0x2e(%ecx)
 8048b46:	1c 45                	sbb    $0x45,%al
 8048b48:	2e 20 48 2e          	and    %cl,%cs:0x2e(%eax)
 8048b4c:	00 44 c3 41          	add    %al,0x41(%ebx,%eax,8)
 8048b50:	c6 41 c7 41          	movb   $0x41,-0x39(%ecx)
 8048b54:	0c 04                	or     $0x4,%al
 8048b56:	04 c5                	add    $0xc5,%al
 8048b58:	1c 00                	sbb    $0x0,%al
 8048b5a:	00 00                	add    %al,(%eax)
 8048b5c:	58                   	pop    %eax
 8048b5d:	02 00                	add    (%eax),%al
 8048b5f:	00 d7                	add    %dl,%bh
 8048b61:	fa                   	cli    
 8048b62:	ff                   	(bad)  
 8048b63:	ff 2d 00 00 00 00    	ljmp   *0x0
 8048b69:	41                   	inc    %ecx
 8048b6a:	0e                   	push   %cs
 8048b6b:	08 85 02 47 0d 05    	or     %al,0x50d4702(%ebp)
 8048b71:	64 c5 0c 04          	lds    %fs:(%esp,%eax,1),%ecx
 8048b75:	04 00                	add    $0x0,%al
 8048b77:	00 28                	add    %ch,(%eax)
 8048b79:	00 00                	add    %al,(%eax)
 8048b7b:	00 78 02             	add    %bh,0x2(%eax)
 8048b7e:	00 00                	add    %al,(%eax)
 8048b80:	00 f8                	add    %bh,%al
 8048b82:	ff                   	(bad)  
 8048b83:	ff 27                	jmp    *(%edi)
 8048b85:	00 00                	add    %al,(%eax)
 8048b87:	00 00                	add    %al,(%eax)
 8048b89:	44                   	inc    %esp
 8048b8a:	0c 01                	or     $0x1,%al
 8048b8c:	00 49 10             	add    %cl,0x10(%ecx)
 8048b8f:	05 02 75 00 41       	add    $0x41007502,%eax
 8048b94:	0f 03 75 7c          	lsl    0x7c(%ebp),%esi
 8048b98:	06                   	push   %es
 8048b99:	54                   	push   %esp
 8048b9a:	0c 01                	or     $0x1,%al
 8048b9c:	00 c1                	add    %al,%cl
 8048b9e:	41                   	inc    %ecx
 8048b9f:	c5 43 0c             	lds    0xc(%ebx),%eax
 8048ba2:	04 04                	add    $0x4,%al
 8048ba4:	38 00                	cmp    %al,(%eax)
 8048ba6:	00 00                	add    %al,(%eax)
 8048ba8:	a4                   	movsb  %ds:(%esi),%es:(%edi)
 8048ba9:	02 00                	add    (%eax),%al
 8048bab:	00 c4                	add    %al,%ah
 8048bad:	fa                   	cli    
 8048bae:	ff                   	(bad)  
 8048baf:	ff 61 00             	jmp    *0x0(%ecx)
 8048bb2:	00 00                	add    %al,(%eax)
 8048bb4:	00 41 0e             	add    %al,0xe(%ecx)
 8048bb7:	08 85 02 41 0e 0c    	or     %al,0xc0e4102(%ebp)
 8048bbd:	87 03                	xchg   %eax,(%ebx)
 8048bbf:	41                   	inc    %ecx
 8048bc0:	0e                   	push   %cs
 8048bc1:	10 86 04 41 0e 14    	adc    %al,0x140e4104(%esi)
 8048bc7:	83 05 4e 0e 30 02 4a 	addl   $0x4a,0x2300e4e
 8048bce:	0e                   	push   %cs
 8048bcf:	14 41                	adc    $0x41,%al
 8048bd1:	0e                   	push   %cs
 8048bd2:	10 c3                	adc    %al,%bl
 8048bd4:	41                   	inc    %ecx
 8048bd5:	0e                   	push   %cs
 8048bd6:	0c c6                	or     $0xc6,%al
 8048bd8:	41                   	inc    %ecx
 8048bd9:	0e                   	push   %cs
 8048bda:	08 c7                	or     %al,%bh
 8048bdc:	41                   	inc    %ecx
 8048bdd:	0e                   	push   %cs
 8048bde:	04 c5                	add    $0xc5,%al
 8048be0:	10 00                	adc    %al,(%eax)
 8048be2:	00 00                	add    %al,(%eax)
 8048be4:	e0 02                	loopne 8048be8 <labeltable.1747+0x388>
 8048be6:	00 00                	add    %al,(%eax)
 8048be8:	f8                   	clc    
 8048be9:	fa                   	cli    
 8048bea:	ff                   	(bad)  
 8048beb:	ff 02                	incl   (%edx)
 8048bed:	00 00                	add    %al,(%eax)
 8048bef:	00 00                	add    %al,(%eax)
 8048bf1:	00 00                	add    %al,(%eax)
 8048bf3:	00 10                	add    %dl,(%eax)
 8048bf5:	00 00                	add    %al,(%eax)
 8048bf7:	00 f4                	add    %dh,%ah
 8048bf9:	02 00                	add    (%eax),%al
 8048bfb:	00 e6                	add    %ah,%dh
 8048bfd:	fa                   	cli    
 8048bfe:	ff                   	(bad)  
 8048bff:	ff 04 00             	incl   (%eax,%eax,1)
 8048c02:	00 00                	add    %al,(%eax)
 8048c04:	00 00                	add    %al,(%eax)
	...

08048c08 <__FRAME_END__>:
 8048c08:	00 00                	add    %al,(%eax)
	...

Disassembly of section .ctors:

08049c0c <__CTOR_LIST__>:
 8049c0c:	ff                   	(bad)  
 8049c0d:	ff                   	(bad)  
 8049c0e:	ff                   	(bad)  
 8049c0f:	ff 00                	incl   (%eax)

08049c10 <__CTOR_END__>:
 8049c10:	00 00                	add    %al,(%eax)
	...

Disassembly of section .dtors:

08049c14 <__DTOR_LIST__>:
 8049c14:	ff                   	(bad)  
 8049c15:	ff                   	(bad)  
 8049c16:	ff                   	(bad)  
 8049c17:	ff 00                	incl   (%eax)

08049c18 <__DTOR_END__>:
 8049c18:	00 00                	add    %al,(%eax)
	...

Disassembly of section .jcr:

08049c1c <__JCR_END__>:
 8049c1c:	00 00                	add    %al,(%eax)
	...

Disassembly of section .dynamic:

08049c20 <_DYNAMIC>:
 8049c20:	01 00                	add    %eax,(%eax)
 8049c22:	00 00                	add    %al,(%eax)
 8049c24:	10 00                	adc    %al,(%eax)
 8049c26:	00 00                	add    %al,(%eax)
 8049c28:	0c 00                	or     $0x0,%al
 8049c2a:	00 00                	add    %al,(%eax)
 8049c2c:	fc                   	cld    
 8049c2d:	82                   	(bad)  
 8049c2e:	04 08                	add    $0x8,%al
 8049c30:	0d 00 00 00 1c       	or     $0x1c000000,%eax
 8049c35:	87 04 08             	xchg   %eax,(%eax,%ecx,1)
 8049c38:	04 00                	add    $0x0,%al
 8049c3a:	00 00                	add    %al,(%eax)
 8049c3c:	8c 81 04 08 f5 fe    	mov    %es,-0x10af7fc(%ecx)
 8049c42:	ff 6f bc             	ljmp   *-0x44(%edi)
 8049c45:	81 04 08 05 00 00 00 	addl   $0x5,(%eax,%ecx,1)
 8049c4c:	50                   	push   %eax
 8049c4d:	82                   	(bad)  
 8049c4e:	04 08                	add    $0x8,%al
 8049c50:	06                   	push   %es
 8049c51:	00 00                	add    %al,(%eax)
 8049c53:	00 e0                	add    %ah,%al
 8049c55:	81 04 08 0a 00 00 00 	addl   $0xa,(%eax,%ecx,1)
 8049c5c:	55                   	push   %ebp
 8049c5d:	00 00                	add    %al,(%eax)
 8049c5f:	00 0b                	add    %cl,(%ebx)
 8049c61:	00 00                	add    %al,(%eax)
 8049c63:	00 10                	add    %dl,(%eax)
 8049c65:	00 00                	add    %al,(%eax)
 8049c67:	00 15 00 00 00 00    	add    %dl,0x0
 8049c6d:	00 00                	add    %al,(%eax)
 8049c6f:	00 03                	add    %al,(%ebx)
 8049c71:	00 00                	add    %al,(%eax)
 8049c73:	00 f4                	add    %dh,%ah
 8049c75:	9c                   	pushf  
 8049c76:	04 08                	add    $0x8,%al
 8049c78:	02 00                	add    (%eax),%al
 8049c7a:	00 00                	add    %al,(%eax)
 8049c7c:	20 00                	and    %al,(%eax)
 8049c7e:	00 00                	add    %al,(%eax)
 8049c80:	14 00                	adc    $0x0,%al
 8049c82:	00 00                	add    %al,(%eax)
 8049c84:	11 00                	adc    %eax,(%eax)
 8049c86:	00 00                	add    %al,(%eax)
 8049c88:	17                   	pop    %ss
 8049c89:	00 00                	add    %al,(%eax)
 8049c8b:	00 dc                	add    %bl,%ah
 8049c8d:	82                   	(bad)  
 8049c8e:	04 08                	add    $0x8,%al
 8049c90:	11 00                	adc    %eax,(%eax)
 8049c92:	00 00                	add    %al,(%eax)
 8049c94:	d4 82                	aam    $0xffffff82
 8049c96:	04 08                	add    $0x8,%al
 8049c98:	12 00                	adc    (%eax),%al
 8049c9a:	00 00                	add    %al,(%eax)
 8049c9c:	08 00                	or     %al,(%eax)
 8049c9e:	00 00                	add    %al,(%eax)
 8049ca0:	13 00                	adc    (%eax),%eax
 8049ca2:	00 00                	add    %al,(%eax)
 8049ca4:	08 00                	or     %al,(%eax)
 8049ca6:	00 00                	add    %al,(%eax)
 8049ca8:	fe                   	(bad)  
 8049ca9:	ff                   	(bad)  
 8049caa:	ff 6f b4             	ljmp   *-0x4c(%edi)
 8049cad:	82                   	(bad)  
 8049cae:	04 08                	add    $0x8,%al
 8049cb0:	ff                   	(bad)  
 8049cb1:	ff                   	(bad)  
 8049cb2:	ff 6f 01             	ljmp   *0x1(%edi)
 8049cb5:	00 00                	add    %al,(%eax)
 8049cb7:	00 f0                	add    %dh,%al
 8049cb9:	ff                   	(bad)  
 8049cba:	ff 6f a6             	ljmp   *-0x5a(%edi)
 8049cbd:	82                   	(bad)  
 8049cbe:	04 08                	add    $0x8,%al
	...

Disassembly of section .got:

08049cf0 <.got>:
 8049cf0:	00 00                	add    %al,(%eax)
	...

Disassembly of section .got.plt:

08049cf4 <_GLOBAL_OFFSET_TABLE_>:
 8049cf4:	20 9c 04 08 00 00 00 	and    %bl,0x8(%esp,%eax,1)
 8049cfb:	00 00                	add    %al,(%eax)
 8049cfd:	00 00                	add    %al,(%eax)
 8049cff:	00 42 83             	add    %al,-0x7d(%edx)
 8049d02:	04 08                	add    $0x8,%al
 8049d04:	52                   	push   %edx
 8049d05:	83 04 08 62          	addl   $0x62,(%eax,%ecx,1)
 8049d09:	83 04 08 72          	addl   $0x72,(%eax,%ecx,1)
 8049d0d:	83                   	.byte 0x83
 8049d0e:	04 08                	add    $0x8,%al

Disassembly of section .data:

08049d10 <__data_start>:
 8049d10:	00 00                	add    %al,(%eax)
	...

08049d14 <__dso_handle>:
 8049d14:	00 00                	add    %al,(%eax)
	...

Disassembly of section .bss:

08049d18 <completed.5499>:
 8049d18:	00 00                	add    %al,(%eax)
	...

08049d1c <dtor_idx.5501>:
 8049d1c:	00 00                	add    %al,(%eax)
	...

Disassembly of section .comment:

00000000 <.comment>:
   0:	47                   	inc    %edi
   1:	43                   	inc    %ebx
   2:	43                   	inc    %ebx
   3:	3a 20                	cmp    (%eax),%ah
   5:	28 47 4e             	sub    %al,0x4e(%edi)
   8:	55                   	push   %ebp
   9:	29 20                	sub    %esp,(%eax)
   b:	34 2e                	xor    $0x2e,%al
   d:	36 2e 30 20          	ss xor %ah,%cs:%ss:(%eax)
  11:	32 30                	xor    (%eax),%dh
  13:	31 31                	xor    %esi,(%ecx)
  15:	30 36                	xor    %dh,(%esi)
  17:	30 33                	xor    %dh,(%ebx)
  19:	20 28                	and    %ch,(%eax)
  1b:	70 72                	jo     8f <_init-0x804826d>
  1d:	65                   	gs
  1e:	72 65                	jb     85 <_init-0x8048277>
  20:	6c                   	insb   (%dx),%es:(%edi)
  21:	65                   	gs
  22:	61                   	popa   
  23:	73 65                	jae    8a <_init-0x8048272>
  25:	29 00                	sub    %eax,(%eax)
  27:	47                   	inc    %edi
  28:	43                   	inc    %ebx
  29:	43                   	inc    %ebx
  2a:	3a 20                	cmp    (%eax),%ah
  2c:	28 47 4e             	sub    %al,0x4e(%edi)
  2f:	55                   	push   %ebp
  30:	29 20                	sub    %esp,(%eax)
  32:	34 2e                	xor    $0x2e,%al
  34:	36 2e 31 00          	ss xor %eax,%cs:%ss:(%eax)
