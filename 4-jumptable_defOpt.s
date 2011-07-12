; 4-jumptable.c w/ default GCC optimizations, 32-bit x86
; A comparison of implementations for large conditional statements.
;       switch statements
;       function pointers
;       goto labels
; Assembly output commented by Eugene Ma
; gcc 4-jumptable.c && objdump -D a.out > 4-jumptable_defOpt.s

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
 8048177:	00 d4                	add    %dl,%ah
 8048179:	51                   	push   %ecx
 804817a:	7e 7a                	jle    80481f6 <_init-0x106>
 804817c:	04 b6                	add    $0xb6,%al
 804817e:	7e cb                	jle    804814b <_init-0x1b1>
 8048180:	b6 ff                	mov    $0xff,%dh
 8048182:	ca 12 89             	lret   $0x8912
 8048185:	ca 02 94             	lret   $0x9402
 8048188:	fe                   	(bad)  
 8048189:	d0 21                	shlb   (%ecx)
 804818b:	07                   	pop    %es

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
 8048233:	00 c0                	add    %al,%al
 8048235:	85 04 08             	test   %eax,(%eax,%ecx,1)
 8048238:	10 00                	adc    %al,(%eax)
 804823a:	00 00                	add    %al,(%eax)
 804823c:	12 00                	adc    (%eax),%al
 804823e:	0e                   	push   %cs
 804823f:	00 1a                	add    %bl,(%edx)
 8048241:	00 00                	add    %al,(%eax)
 8048243:	00 2c 88             	add    %ch,(%eax,%ecx,4)
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
 80482d4:	00 9d 04 08 06 01    	add    %bl,0x1060804(%ebp)
	...

Disassembly of section .rel.plt:

080482dc <.rel.plt>:
 80482dc:	10 9d 04 08 07 01    	adc    %bl,0x1070804(%ebp)
 80482e2:	00 00                	add    %al,(%eax)
 80482e4:	14 9d                	adc    $0x9d,%al
 80482e6:	04 08                	add    $0x8,%al
 80482e8:	07                   	pop    %es
 80482e9:	02 00                	add    (%eax),%al
 80482eb:	00 18                	add    %bl,(%eax)
 80482ed:	9d                   	popf   
 80482ee:	04 08                	add    $0x8,%al
 80482f0:	07                   	pop    %es
 80482f1:	03 00                	add    (%eax),%eax
 80482f3:	00 1c 9d 04 08 07 04 	add    %bl,0x4070804(,%ebx,4)
	...

Disassembly of section .init:

080482fc <_init>:
 80482fc:	53                   	push   %ebx
 80482fd:	83 ec 08             	sub    $0x8,%esp
 8048300:	e8 00 00 00 00       	call   8048305 <_init+0x9>
 8048305:	5b                   	pop    %ebx
 8048306:	81 c3 ff 19 00 00    	add    $0x19ff,%ebx
 804830c:	8b 83 fc ff ff ff    	mov    -0x4(%ebx),%eax
 8048312:	85 c0                	test   %eax,%eax
 8048314:	74 05                	je     804831b <_init+0x1f>
 8048316:	e8 21 00 00 00       	call   804833c <__gmon_start__@plt>
 804831b:	e8 f0 00 00 00       	call   8048410 <frame_dummy>
 8048320:	e8 bb 04 00 00       	call   80487e0 <__do_global_ctors_aux>
 8048325:	83 c4 08             	add    $0x8,%esp
 8048328:	5b                   	pop    %ebx
 8048329:	c3                   	ret    

Disassembly of section .plt:

0804832c <__gmon_start__@plt-0x10>:
 804832c:	ff 35 08 9d 04 08    	pushl  0x8049d08
 8048332:	ff 25 0c 9d 04 08    	jmp    *0x8049d0c
 8048338:	00 00                	add    %al,(%eax)
	...

0804833c <__gmon_start__@plt>:
 804833c:	ff 25 10 9d 04 08    	jmp    *0x8049d10
 8048342:	68 00 00 00 00       	push   $0x0
 8048347:	e9 e0 ff ff ff       	jmp    804832c <_init+0x30>

0804834c <__libc_start_main@plt>:
 804834c:	ff 25 14 9d 04 08    	jmp    *0x8049d14
 8048352:	68 08 00 00 00       	push   $0x8
 8048357:	e9 d0 ff ff ff       	jmp    804832c <_init+0x30>

0804835c <printf@plt>:
 804835c:	ff 25 18 9d 04 08    	jmp    *0x8049d18
 8048362:	68 10 00 00 00       	push   $0x10
 8048367:	e9 c0 ff ff ff       	jmp    804832c <_init+0x30>

0804836c <puts@plt>:
 804836c:	ff 25 1c 9d 04 08    	jmp    *0x8049d1c
 8048372:	68 18 00 00 00       	push   $0x18
 8048377:	e9 b0 ff ff ff       	jmp    804832c <_init+0x30>

Disassembly of section .text:

08048380 <_start>:
 8048380:	31 ed                	xor    %ebp,%ebp
 8048382:	5e                   	pop    %esi
 8048383:	89 e1                	mov    %esp,%ecx
 8048385:	83 e4 f0             	and    $0xfffffff0,%esp
 8048388:	50                   	push   %eax
 8048389:	54                   	push   %esp
 804838a:	52                   	push   %edx
 804838b:	68 d0 87 04 08       	push   $0x80487d0
 8048390:	68 60 87 04 08       	push   $0x8048760
 8048395:	51                   	push   %ecx
 8048396:	56                   	push   %esi
 8048397:	68 3c 87 04 08       	push   $0x804873c
 804839c:	e8 ab ff ff ff       	call   804834c <__libc_start_main@plt>
 80483a1:	f4                   	hlt    
 80483a2:	90                   	nop
 80483a3:	90                   	nop
 80483a4:	90                   	nop
 80483a5:	90                   	nop
 80483a6:	90                   	nop
 80483a7:	90                   	nop
 80483a8:	90                   	nop
 80483a9:	90                   	nop
 80483aa:	90                   	nop
 80483ab:	90                   	nop
 80483ac:	90                   	nop
 80483ad:	90                   	nop
 80483ae:	90                   	nop
 80483af:	90                   	nop

080483b0 <__do_global_dtors_aux>:
 80483b0:	55                   	push   %ebp
 80483b1:	89 e5                	mov    %esp,%ebp
 80483b3:	53                   	push   %ebx
 80483b4:	83 ec 04             	sub    $0x4,%esp
 80483b7:	80 3d 48 9d 04 08 00 	cmpb   $0x0,0x8049d48
 80483be:	75 3f                	jne    80483ff <__do_global_dtors_aux+0x4f>
 80483c0:	a1 4c 9d 04 08       	mov    0x8049d4c,%eax
 80483c5:	bb 28 9c 04 08       	mov    $0x8049c28,%ebx
 80483ca:	81 eb 24 9c 04 08    	sub    $0x8049c24,%ebx
 80483d0:	c1 fb 02             	sar    $0x2,%ebx
 80483d3:	83 eb 01             	sub    $0x1,%ebx
 80483d6:	39 d8                	cmp    %ebx,%eax
 80483d8:	73 1e                	jae    80483f8 <__do_global_dtors_aux+0x48>
 80483da:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
 80483e0:	83 c0 01             	add    $0x1,%eax
 80483e3:	a3 4c 9d 04 08       	mov    %eax,0x8049d4c
 80483e8:	ff 14 85 24 9c 04 08 	call   *0x8049c24(,%eax,4)
 80483ef:	a1 4c 9d 04 08       	mov    0x8049d4c,%eax
 80483f4:	39 d8                	cmp    %ebx,%eax
 80483f6:	72 e8                	jb     80483e0 <__do_global_dtors_aux+0x30>
 80483f8:	c6 05 48 9d 04 08 01 	movb   $0x1,0x8049d48
 80483ff:	83 c4 04             	add    $0x4,%esp
 8048402:	5b                   	pop    %ebx
 8048403:	5d                   	pop    %ebp
 8048404:	c3                   	ret    
 8048405:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
 8048409:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

08048410 <frame_dummy>:
 8048410:	55                   	push   %ebp
 8048411:	89 e5                	mov    %esp,%ebp
 8048413:	83 ec 18             	sub    $0x18,%esp
 8048416:	a1 2c 9c 04 08       	mov    0x8049c2c,%eax
 804841b:	85 c0                	test   %eax,%eax
 804841d:	74 12                	je     8048431 <frame_dummy+0x21>
 804841f:	b8 00 00 00 00       	mov    $0x0,%eax
 8048424:	85 c0                	test   %eax,%eax
 8048426:	74 09                	je     8048431 <frame_dummy+0x21>
 8048428:	c7 04 24 2c 9c 04 08 	movl   $0x8049c2c,(%esp)
 804842f:	ff d0                	call   *%eax
 8048431:	c9                   	leave  
 8048432:	c3                   	ret    
 8048433:	90                   	nop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;int switch_dispatch(int op, int x, int y)
08048434 <switch_dispatch>:
 8048434:	55                   	push   %ebp ; save old frame pointer    
 8048435:	89 e5                	mov    %esp,%ebp ; reset frame pointer
 8048437:	83 ec 18             	sub    $0x18,%esp ; allocate local variables w/ stack alignment
 804843a:	83 7d 08 14          	cmpl   $0x14,0x8(%ebp) ; compare argument op to 20
 804843e:	77 58                	ja     8048498 <switch_dispatch+0x64> ; store -1 in eax and exit if above
 8048440:	8b 45 08             	mov    0x8(%ebp),%eax ; EAX = op 
 8048443:	c1 e0 02             	shl    $0x2,%eax ; EAX = 4 * op = jump table index
 8048446:	05 a0 88 04 08       	add    $0x80488a0,%eax ; jump table starts @ 0x80488a4
 804844b:	8b 00                	mov    (%eax),%eax ; index into jump table with op
 804844d:	ff e0                	jmp    *%eax ; jump to specified location
 804844f:	8b 45 10             	mov    0x10(%ebp),%eax ; EAX = y
 8048452:	8b 55 0c             	mov    0xc(%ebp),%edx ; EDX = x
 8048455:	01 d0                	add    %edx,%eax ; EAX = x + y
 8048457:	eb 44                	jmp    804849d <switch_dispatch+0x69> ; exit
 8048459:	8b 45 0c             	mov    0xc(%ebp),%eax ; EAX = x
 804845c:	0f af 45 10          	imul   0x10(%ebp),%eax ; EAX = x * y
 8048460:	eb 3b                	jmp    804849d <switch_dispatch+0x69> ; exit
 8048462:	8b 45 0c             	mov    0xc(%ebp),%eax ; EAX = x
 8048465:	89 c2                	mov    %eax,%edx ; EDX = x
 8048467:	c1 fa 1f             	sar    $0x1f,%edx ; EDX >> 31, sign is preserved
 804846a:	f7 7d 10             	idivl  0x10(%ebp) ; EDX:EAX / y, quotient returned in EAX
 804846d:	eb 2e                	jmp    804849d <switch_dispatch+0x69> ; exit
 804846f:	8b 45 10             	mov    0x10(%ebp),%eax ; EAX = y
 8048472:	8b 55 0c             	mov    0xc(%ebp),%edx ; EDX = x
 8048475:	89 d1                	mov    %edx,%ecx ; ECX = EDX
 8048477:	29 c1                	sub    %eax,%ecx ; ECX = x - y
 8048479:	89 c8                	mov    %ecx,%eax ; EAX = ECX
 804847b:	eb 20                	jmp    804849d <switch_dispatch+0x69> ; exit
 804847d:	c7 04 24 30 88 04 08 	movl   $0x8048830,(%esp) ; push address of error string
 8048484:	e8 e3 fe ff ff       	call   804836c <puts@plt> ; write to stdout
 8048489:	eb 0d                	jmp    8048498 <switch_dispatch+0x64> ; store -1 in EAX and exit
 804848b:	c7 04 24 68 88 04 08 	movl   $0x8048868,(%esp) ; push address of error string
 8048492:	e8 d5 fe ff ff       	call   804836c <puts@plt> ; write to stdout
 8048497:	90                   	nop
 8048498:	b8 ff ff ff ff       	mov    $0xffffffff,%eax ; <switch_dispatch+0x64> store -1 in EAX
 804849d:	c9                   	leave  ; <switch_dispatch+0x69> all branches eventually reach this point 
 804849e:	c3                   	ret    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

0804849f <print_sw.1708>:
 804849f:	55                   	push   %ebp
 80484a0:	89 e5                	mov    %esp,%ebp
 80484a2:	83 ec 28             	sub    $0x28,%esp
 80484a5:	8b 45 10             	mov    0x10(%ebp),%eax
 80484a8:	89 44 24 08          	mov    %eax,0x8(%esp)
 80484ac:	8b 45 0c             	mov    0xc(%ebp),%eax
 80484af:	89 44 24 04          	mov    %eax,0x4(%esp)
 80484b3:	8b 45 08             	mov    0x8(%ebp),%eax
 80484b6:	89 04 24             	mov    %eax,(%esp)
 80484b9:	e8 76 ff ff ff       	call   8048434 <switch_dispatch>
 80484be:	ba f4 88 04 08       	mov    $0x80488f4,%edx
 80484c3:	89 44 24 10          	mov    %eax,0x10(%esp)
 80484c7:	8b 45 10             	mov    0x10(%ebp),%eax
 80484ca:	89 44 24 0c          	mov    %eax,0xc(%esp)
 80484ce:	8b 45 0c             	mov    0xc(%ebp),%eax
 80484d1:	89 44 24 08          	mov    %eax,0x8(%esp)
 80484d5:	8b 45 08             	mov    0x8(%ebp),%eax
 80484d8:	89 44 24 04          	mov    %eax,0x4(%esp)
 80484dc:	89 14 24             	mov    %edx,(%esp)
 80484df:	e8 78 fe ff ff       	call   804835c <printf@plt>
 80484e4:	c9                   	leave  
 80484e5:	c3                   	ret    

080484e6 <switch_helper>:
 80484e6:	55                   	push   %ebp
 80484e7:	89 e5                	mov    %esp,%ebp
 80484e9:	83 ec 18             	sub    $0x18,%esp
 80484ec:	c7 44 24 08 05 00 00 	movl   $0x5,0x8(%esp)
 80484f3:	00 
 80484f4:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
 80484fb:	00 
 80484fc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
 8048503:	e8 97 ff ff ff       	call   804849f <print_sw.1708>
 8048508:	c7 44 24 08 02 00 00 	movl   $0x2,0x8(%esp)
 804850f:	00 
 8048510:	c7 44 24 04 08 00 00 	movl   $0x8,0x4(%esp)
 8048517:	00 
 8048518:	c7 04 24 03 00 00 00 	movl   $0x3,(%esp)
 804851f:	e8 7b ff ff ff       	call   804849f <print_sw.1708>
 8048524:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
 804852b:	00 
 804852c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
 8048533:	00 
 8048534:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
 804853b:	e8 f4 fe ff ff       	call   8048434 <switch_dispatch>
 8048540:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
 8048547:	00 
 8048548:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
 804854f:	00 
 8048550:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
 8048557:	e8 d8 fe ff ff       	call   8048434 <switch_dispatch>
 804855c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
 8048563:	00 
 8048564:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
 804856b:	00 
 804856c:	c7 04 24 0f 00 00 00 	movl   $0xf,(%esp)
 8048573:	e8 bc fe ff ff       	call   8048434 <switch_dispatch>
 8048578:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
 804857f:	00 
 8048580:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
 8048587:	00 
 8048588:	c7 04 24 14 00 00 00 	movl   $0x14,(%esp)
 804858f:	e8 a0 fe ff ff       	call   8048434 <switch_dispatch>
 8048594:	c9                   	leave  
 8048595:	c3                   	ret    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; int add(int x, int y);
08048596 <add>:
 8048596:	55                   	push   %ebp ; save old frame pointer
 8048597:	89 e5                	mov    %esp,%ebp ; update frame pointer
 8048599:	8b 45 0c             	mov    0xc(%ebp),%eax ; EAX = y
 804859c:	8b 55 08             	mov    0x8(%ebp),%edx ; EDX = x
 804859f:	01 d0                	add    %edx,%eax ; EAX = x + y
 80485a1:	5d                   	pop    %ebp ; recover old frame pointer
 80485a2:	c3                   	ret    ; return to caller

; int sub(int x, int y);
080485a3 <sub>:
 80485a3:	55                   	push   %ebp ; see <add>
 80485a4:	89 e5                	mov    %esp,%ebp
 80485a6:	8b 45 0c             	mov    0xc(%ebp),%eax ; EAX = y
 80485a9:	8b 55 08             	mov    0x8(%ebp),%edx ; EDX = x
 80485ac:	89 d1                	mov    %edx,%ecx ; ECX = x
 80485ae:	29 c1                	sub    %eax,%ecx ; ECX = x - y
 80485b0:	89 c8                	mov    %ecx,%eax ; EAX = x - y
 80485b2:	5d                   	pop    %ebp
 80485b3:	c3                   	ret    

; int mul(int x, int y);
080485b4 <mul>:
 80485b4:	55                   	push   %ebp ; see <add>
 80485b5:	89 e5                	mov    %esp,%ebp
 80485b7:	8b 45 08             	mov    0x8(%ebp),%eax
 80485ba:	0f af 45 0c          	imul   0xc(%ebp),%eax
 80485be:	5d                   	pop    %ebp
 80485bf:	c3                   	ret    

; int div(int x, int y);
080485c0 <div>:
 80485c0:	55                   	push   %ebp ; save old frame pointer
 80485c1:	89 e5                	mov    %esp,%ebp ; update frame pointer
 80485c3:	8b 45 08             	mov    0x8(%ebp),%eax ; EAX = x
 80485c6:	89 c2                	mov    %eax,%edx ; EDX = x
 80485c8:	c1 fa 1f             	sar    $0x1f,%edx ; EDX >> 31, preserve sign
 80485cb:	f7 7d 0c             	idivl  0xc(%ebp) ; EDX:EAX / y, quotient in EAX
 80485ce:	5d                   	pop    %ebp ; recover old frame pointer
 80485cf:	c3                   	ret     ; return to caller

; int func_dispatch(int op, int x, int y)
080485d0 <func_dispatch>:
                                        ; save EBP
 80485d0:	55                   	push   %ebp
                                        ; update EBP
 80485d1:	89 e5                	mov    %esp,%ebp
                                        ; allocate local storage
 80485d3:	83 ec 18             	sub    $0x18,%esp
                                        ; EAX = op
 80485d6:	8b 45 08             	mov    0x8(%ebp),%eax
                                        ; index into jumptable to get "handler" location
                                        ; EDX = [4*op + 0x8049d38] (jump table seems to be missing OP_ADD)
                                        ; ex. if op = OP_SUB, EDX = 0x80485a3 <sub>
 80485d9:	8b 14 85 38 9d 04 08 	mov    0x8049d38(,%eax,4),%edx
                                        ; EAX = y
 80485e0:	8b 45 10             	mov    0x10(%ebp),%eax
                                        ; Store y on stack within local storage
 80485e3:	89 44 24 04          	mov    %eax,0x4(%esp)
                                        ; EAX = x
 80485e7:	8b 45 0c             	mov    0xc(%ebp),%eax
                                        ; Store x on stack within local storage
 80485ea:	89 04 24             	mov    %eax,(%esp)
                                        ; Arguments loaded on stack: first x, then y
                                        ; jump to "handler" function with arguments loaded on stack
 80485ed:	ff d2                	call   *%edx
 80485ef:	c9                   	leave  
 80485f0:	c3                   	ret    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

080485f1 <print_func.1740>:
 80485f1:	55                   	push   %ebp
 80485f2:	89 e5                	mov    %esp,%ebp
 80485f4:	83 ec 28             	sub    $0x28,%esp
 80485f7:	8b 45 10             	mov    0x10(%ebp),%eax
 80485fa:	89 44 24 08          	mov    %eax,0x8(%esp)
 80485fe:	8b 45 0c             	mov    0xc(%ebp),%eax
 8048601:	89 44 24 04          	mov    %eax,0x4(%esp)
 8048605:	8b 45 08             	mov    0x8(%ebp),%eax
 8048608:	89 04 24             	mov    %eax,(%esp)
 804860b:	e8 c0 ff ff ff       	call   80485d0 <func_dispatch>
 8048610:	ba 0f 89 04 08       	mov    $0x804890f,%edx
 8048615:	89 44 24 10          	mov    %eax,0x10(%esp)
 8048619:	8b 45 10             	mov    0x10(%ebp),%eax
 804861c:	89 44 24 0c          	mov    %eax,0xc(%esp)
 8048620:	8b 45 0c             	mov    0xc(%ebp),%eax
 8048623:	89 44 24 08          	mov    %eax,0x8(%esp)
 8048627:	8b 45 08             	mov    0x8(%ebp),%eax
 804862a:	89 44 24 04          	mov    %eax,0x4(%esp)
 804862e:	89 14 24             	mov    %edx,(%esp)
 8048631:	e8 26 fd ff ff       	call   804835c <printf@plt>
 8048636:	c9                   	leave  
 8048637:	c3                   	ret    

08048638 <func_helper>:
 8048638:	55                   	push   %ebp
 8048639:	89 e5                	mov    %esp,%ebp
 804863b:	83 ec 18             	sub    $0x18,%esp
 804863e:	c7 44 24 08 05 00 00 	movl   $0x5,0x8(%esp)
 8048645:	00 
 8048646:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
 804864d:	00 
 804864e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
 8048655:	e8 97 ff ff ff       	call   80485f1 <print_func.1740>
 804865a:	c7 44 24 08 02 00 00 	movl   $0x2,0x8(%esp)
 8048661:	00 
 8048662:	c7 44 24 04 08 00 00 	movl   $0x8,0x4(%esp)
 8048669:	00 
 804866a:	c7 04 24 03 00 00 00 	movl   $0x3,(%esp)
 8048671:	e8 7b ff ff ff       	call   80485f1 <print_func.1740>
 8048676:	c9                   	leave  
 8048677:	c3                   	ret    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; int goto_dispatch(int op, int x, int y)
; Does not allocate local storage!
08048678 <goto_dispatch>:
                                        ; save old frame pointer
 8048678:	55                   	push   %ebp 
                                        ; update frame pointer
 8048679:	89 e5                	mov    %esp,%ebp 
                                        ; EAX = op
 804867b:	8b 45 08             	mov    0x8(%ebp),%eax ; EAX = op
                                        ; index into labeltable
 804867e:	8b 04 85 28 9d 04 08 	mov    0x8049d28(,%eax,4),%eax 
                                        ; jump to "handler"
 8048685:	ff e0                	jmp    *%eax
                                        ; &&l_add
 8048687:	8b 45 10             	mov    0x10(%ebp),%eax ; EAX = y
 804868a:	8b 55 0c             	mov    0xc(%ebp),%edx ; EDX = x
 804868d:	01 d0                	add    %edx,%eax ; EAX = x + y
 804868f:	eb 22                	jmp    80486b3 <goto_dispatch+0x3b>
                                        ; &&l_sub
                                        ; Why doesn't GCC just do this?
                                        ; mov (x), EAX
                                        ; mov (y), EDX
                                        ; sub EDX, EAX
 8048691:	8b 45 10             	mov    0x10(%ebp),%eax ; EAX = y
 8048694:	8b 55 0c             	mov    0xc(%ebp),%edx ; EDX = x
 8048697:	89 d1                	mov    %edx,%ecx ; ECX = x
 8048699:	29 c1                	sub    %eax,%ecx ; ECX = x - y
 804869b:	89 c8                	mov    %ecx,%eax ; EAX = x - y
 804869d:	eb 14                	jmp    80486b3 <goto_dispatch+0x3b>
                                        ; &&l_mul
 804869f:	8b 45 0c             	mov    0xc(%ebp),%eax ; EAX = x
 80486a2:	0f af 45 10          	imul   0x10(%ebp),%eax ; EAX = x * y
 80486a6:	eb 0b                	jmp    80486b3 <goto_dispatch+0x3b>
                                        ; &&l_div
 80486a8:	8b 45 0c             	mov    0xc(%ebp),%eax ; EAX = x
 80486ab:	89 c2                	mov    %eax,%edx ; EDX = x
 80486ad:	c1 fa 1f             	sar    $0x1f,%edx ; EDX >> 31, sign is preserved
 80486b0:	f7 7d 10             	idivl  0x10(%ebp) ; EAX contians quotient
                                        ;  All branches jump here to exit
 80486b3:	5d                   	pop    %ebp
 80486b4:	c3                   	ret    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

080486b5 <print_goto.1758>:
 80486b5:	55                   	push   %ebp
 80486b6:	89 e5                	mov    %esp,%ebp
 80486b8:	83 ec 28             	sub    $0x28,%esp
 80486bb:	8b 45 10             	mov    0x10(%ebp),%eax
 80486be:	89 44 24 08          	mov    %eax,0x8(%esp)
 80486c2:	8b 45 0c             	mov    0xc(%ebp),%eax
 80486c5:	89 44 24 04          	mov    %eax,0x4(%esp)
 80486c9:	8b 45 08             	mov    0x8(%ebp),%eax
 80486cc:	89 04 24             	mov    %eax,(%esp)
 80486cf:	e8 a4 ff ff ff       	call   8048678 <goto_dispatch>
 80486d4:	ba 2a 89 04 08       	mov    $0x804892a,%edx
 80486d9:	89 44 24 10          	mov    %eax,0x10(%esp)
 80486dd:	8b 45 10             	mov    0x10(%ebp),%eax
 80486e0:	89 44 24 0c          	mov    %eax,0xc(%esp)
 80486e4:	8b 45 0c             	mov    0xc(%ebp),%eax
 80486e7:	89 44 24 08          	mov    %eax,0x8(%esp)
 80486eb:	8b 45 08             	mov    0x8(%ebp),%eax
 80486ee:	89 44 24 04          	mov    %eax,0x4(%esp)
 80486f2:	89 14 24             	mov    %edx,(%esp)
 80486f5:	e8 62 fc ff ff       	call   804835c <printf@plt>
 80486fa:	c9                   	leave  
 80486fb:	c3                   	ret    

080486fc <goto_helper>:
 80486fc:	55                   	push   %ebp
 80486fd:	89 e5                	mov    %esp,%ebp
 80486ff:	83 ec 18             	sub    $0x18,%esp
 8048702:	c7 44 24 08 05 00 00 	movl   $0x5,0x8(%esp)
 8048709:	00 
 804870a:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
 8048711:	00 
 8048712:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
 8048719:	e8 97 ff ff ff       	call   80486b5 <print_goto.1758>
 804871e:	c7 44 24 08 02 00 00 	movl   $0x2,0x8(%esp)
 8048725:	00 
 8048726:	c7 44 24 04 08 00 00 	movl   $0x8,0x4(%esp)
 804872d:	00 
 804872e:	c7 04 24 03 00 00 00 	movl   $0x3,(%esp)
 8048735:	e8 7b ff ff ff       	call   80486b5 <print_goto.1758>
 804873a:	c9                   	leave  
 804873b:	c3                   	ret    

0804873c <main>:
 804873c:	55                   	push   %ebp
 804873d:	89 e5                	mov    %esp,%ebp
 804873f:	83 e4 f0             	and    $0xfffffff0,%esp
 8048742:	e8 9f fd ff ff       	call   80484e6 <switch_helper>
 8048747:	e8 ec fe ff ff       	call   8048638 <func_helper>
 804874c:	e8 ab ff ff ff       	call   80486fc <goto_helper>
 8048751:	b8 00 00 00 00       	mov    $0x0,%eax
 8048756:	c9                   	leave  
 8048757:	c3                   	ret    
 8048758:	90                   	nop
 8048759:	90                   	nop
 804875a:	90                   	nop
 804875b:	90                   	nop
 804875c:	90                   	nop
 804875d:	90                   	nop
 804875e:	90                   	nop
 804875f:	90                   	nop

08048760 <__libc_csu_init>:
 8048760:	55                   	push   %ebp
 8048761:	57                   	push   %edi
 8048762:	56                   	push   %esi
 8048763:	53                   	push   %ebx
 8048764:	e8 69 00 00 00       	call   80487d2 <__i686.get_pc_thunk.bx>
 8048769:	81 c3 9b 15 00 00    	add    $0x159b,%ebx
 804876f:	83 ec 1c             	sub    $0x1c,%esp
 8048772:	8b 6c 24 30          	mov    0x30(%esp),%ebp
 8048776:	8d bb 18 ff ff ff    	lea    -0xe8(%ebx),%edi
 804877c:	e8 7b fb ff ff       	call   80482fc <_init>
 8048781:	8d 83 18 ff ff ff    	lea    -0xe8(%ebx),%eax
 8048787:	29 c7                	sub    %eax,%edi
 8048789:	c1 ff 02             	sar    $0x2,%edi
 804878c:	85 ff                	test   %edi,%edi
 804878e:	74 29                	je     80487b9 <__libc_csu_init+0x59>
 8048790:	31 f6                	xor    %esi,%esi
 8048792:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
 8048798:	8b 44 24 38          	mov    0x38(%esp),%eax
 804879c:	89 2c 24             	mov    %ebp,(%esp)
 804879f:	89 44 24 08          	mov    %eax,0x8(%esp)
 80487a3:	8b 44 24 34          	mov    0x34(%esp),%eax
 80487a7:	89 44 24 04          	mov    %eax,0x4(%esp)
 80487ab:	ff 94 b3 18 ff ff ff 	call   *-0xe8(%ebx,%esi,4)
 80487b2:	83 c6 01             	add    $0x1,%esi
 80487b5:	39 fe                	cmp    %edi,%esi
 80487b7:	75 df                	jne    8048798 <__libc_csu_init+0x38>
 80487b9:	83 c4 1c             	add    $0x1c,%esp
 80487bc:	5b                   	pop    %ebx
 80487bd:	5e                   	pop    %esi
 80487be:	5f                   	pop    %edi
 80487bf:	5d                   	pop    %ebp
 80487c0:	c3                   	ret    
 80487c1:	eb 0d                	jmp    80487d0 <__libc_csu_fini>
 80487c3:	90                   	nop
 80487c4:	90                   	nop
 80487c5:	90                   	nop
 80487c6:	90                   	nop
 80487c7:	90                   	nop
 80487c8:	90                   	nop
 80487c9:	90                   	nop
 80487ca:	90                   	nop
 80487cb:	90                   	nop
 80487cc:	90                   	nop
 80487cd:	90                   	nop
 80487ce:	90                   	nop
 80487cf:	90                   	nop

080487d0 <__libc_csu_fini>:
 80487d0:	f3 c3                	repz ret 

080487d2 <__i686.get_pc_thunk.bx>:
 80487d2:	8b 1c 24             	mov    (%esp),%ebx
 80487d5:	c3                   	ret    
 80487d6:	90                   	nop
 80487d7:	90                   	nop
 80487d8:	90                   	nop
 80487d9:	90                   	nop
 80487da:	90                   	nop
 80487db:	90                   	nop
 80487dc:	90                   	nop
 80487dd:	90                   	nop
 80487de:	90                   	nop
 80487df:	90                   	nop

080487e0 <__do_global_ctors_aux>:
 80487e0:	55                   	push   %ebp
 80487e1:	89 e5                	mov    %esp,%ebp
 80487e3:	53                   	push   %ebx
 80487e4:	83 ec 04             	sub    $0x4,%esp
 80487e7:	a1 1c 9c 04 08       	mov    0x8049c1c,%eax
 80487ec:	83 f8 ff             	cmp    $0xffffffff,%eax
 80487ef:	74 13                	je     8048804 <__do_global_ctors_aux+0x24>
 80487f1:	bb 1c 9c 04 08       	mov    $0x8049c1c,%ebx
 80487f6:	66 90                	xchg   %ax,%ax
 80487f8:	83 eb 04             	sub    $0x4,%ebx
 80487fb:	ff d0                	call   *%eax
 80487fd:	8b 03                	mov    (%ebx),%eax
 80487ff:	83 f8 ff             	cmp    $0xffffffff,%eax
 8048802:	75 f4                	jne    80487f8 <__do_global_ctors_aux+0x18>
 8048804:	83 c4 04             	add    $0x4,%esp
 8048807:	5b                   	pop    %ebx
 8048808:	5d                   	pop    %ebp
 8048809:	c3                   	ret    
 804880a:	90                   	nop
 804880b:	90                   	nop

Disassembly of section .fini:

0804880c <_fini>:
 804880c:	53                   	push   %ebx
 804880d:	83 ec 08             	sub    $0x8,%esp
 8048810:	e8 00 00 00 00       	call   8048815 <_fini+0x9>
 8048815:	5b                   	pop    %ebx
 8048816:	81 c3 ef 14 00 00    	add    $0x14ef,%ebx
 804881c:	e8 8f fb ff ff       	call   80483b0 <__do_global_dtors_aux>
 8048821:	83 c4 08             	add    $0x8,%esp
 8048824:	5b                   	pop    %ebx
 8048825:	c3                   	ret    

Disassembly of section .rodata:

08048828 <_fp_hw>:
 8048828:	03 00                	add    (%eax),%eax
	...

0804882c <_IO_stdin_used>:
 804882c:	01 00                	add    %eax,(%eax)
 804882e:	02 00                	add    (%eax),%al
 8048830:	73 77                	jae    80488a9 <_IO_stdin_used+0x7d>
 8048832:	69 74 63 68 5f 64 69 	imul   $0x7369645f,0x68(%ebx,%eiz,2),%esi
 8048839:	73 
 804883a:	70 61                	jo     804889d <_IO_stdin_used+0x71>
 804883c:	74 63                	je     80488a1 <_IO_stdin_used+0x75>
 804883e:	68 20 69 6e 76       	push   $0x766e6920
 8048843:	6f                   	outsl  %ds:(%esi),(%dx)
 8048844:	6b 65 64 20          	imul   $0x20,0x64(%ebp),%esp
 8048848:	77 69                	ja     80488b3 <_IO_stdin_used+0x87>
 804884a:	74 68                	je     80488b4 <_IO_stdin_used+0x88>
 804884c:	20 6f 70             	and    %ch,0x70(%edi)
 804884f:	63 6f 64             	arpl   %bp,0x64(%edi)
 8048852:	65 20 69 6e          	and    %ch,%gs:0x6e(%ecx)
 8048856:	20 72 61             	and    %dh,0x61(%edx)
 8048859:	6e                   	outsb  %ds:(%esi),(%dx)
 804885a:	67 65 20 37          	and    %dh,%gs:(%bx)
 804885e:	20 74 6f 20          	and    %dh,0x20(%edi,%ebp,2)
 8048862:	31 30                	xor    %esi,(%eax)
 8048864:	00 00                	add    %al,(%eax)
 8048866:	00 00                	add    %al,(%eax)
 8048868:	73 77                	jae    80488e1 <_IO_stdin_used+0xb5>
 804886a:	69 74 63 68 5f 64 69 	imul   $0x7369645f,0x68(%ebx,%eiz,2),%esi
 8048871:	73 
 8048872:	70 61                	jo     80488d5 <_IO_stdin_used+0xa9>
 8048874:	74 63                	je     80488d9 <_IO_stdin_used+0xad>
 8048876:	68 20 69 6e 76       	push   $0x766e6920
 804887b:	6f                   	outsl  %ds:(%esi),(%dx)
 804887c:	6b 65 64 20          	imul   $0x20,0x64(%ebp),%esp
 8048880:	77 69                	ja     80488eb <_IO_stdin_used+0xbf>
 8048882:	74 68                	je     80488ec <_IO_stdin_used+0xc0>
 8048884:	20 6f 70             	and    %ch,0x70(%edi)
 8048887:	63 6f 64             	arpl   %bp,0x64(%edi)
 804888a:	65 20 69 6e          	and    %ch,%gs:0x6e(%ecx)
 804888e:	20 72 61             	and    %dh,0x61(%edx)
 8048891:	6e                   	outsb  %ds:(%esi),(%dx)
 8048892:	67 65 20 31          	and    %dh,%gs:(%bx,%di)
 8048896:	35 20 74 6f 20       	xor    $0x206f7420,%eax
 804889b:	32 30                	xor    (%eax),%dh
 804889d:	00 00                	add    %al,(%eax)
; switch_dispatch table starts here
 804889f:	00 4f 84             	add    %cl,-0x7c(%edi)
 80488a2:	04 08                	add    $0x8,%al
 80488a4:	6f                   	outsl  %ds:(%esi),(%dx)
 80488a5:	84 04 08             	test   %al,(%eax,%ecx,1)
 80488a8:	59                   	pop    %ecx
 80488a9:	84 04 08             	test   %al,(%eax,%ecx,1)
 80488ac:	62 84 04 08 98 84 04 	bound  %eax,0x4849808(%esp,%eax,1)
 80488b3:	08 98 84 04 08 98    	or     %bl,-0x67f7fb7c(%eax)
 80488b9:	84 04 08             	test   %al,(%eax,%ecx,1)
 80488bc:	7d 84                	jge    8048842 <_IO_stdin_used+0x16>
 80488be:	04 08                	add    $0x8,%al
 80488c0:	7d 84                	jge    8048846 <_IO_stdin_used+0x1a>
 80488c2:	04 08                	add    $0x8,%al
 80488c4:	7d 84                	jge    804884a <_IO_stdin_used+0x1e>
 80488c6:	04 08                	add    $0x8,%al
 80488c8:	7d 84                	jge    804884e <_IO_stdin_used+0x22>
 80488ca:	04 08                	add    $0x8,%al
 80488cc:	98                   	cwtl   
 80488cd:	84 04 08             	test   %al,(%eax,%ecx,1)
 80488d0:	98                   	cwtl   
 80488d1:	84 04 08             	test   %al,(%eax,%ecx,1)
 80488d4:	98                   	cwtl   
 80488d5:	84 04 08             	test   %al,(%eax,%ecx,1)
 80488d8:	98                   	cwtl   
 80488d9:	84 04 08             	test   %al,(%eax,%ecx,1)
 80488dc:	8b 84 04 08 8b 84 04 	mov    0x4848b08(%esp,%eax,1),%eax
 80488e3:	08 8b 84 04 08 8b    	or     %cl,-0x74f7fb7c(%ebx)
 80488e9:	84 04 08             	test   %al,(%eax,%ecx,1)
 80488ec:	8b 84 04 08 8b 84 04 	mov    0x4848b08(%esp,%eax,1),%eax
 80488f3:	08 53 57             	or     %dl,0x57(%ebx)
 80488f6:	43                   	inc    %ebx
 80488f7:	48                   	dec    %eax
 80488f8:	3a 20                	cmp    (%eax),%ah
 80488fa:	6f                   	outsl  %ds:(%esi),(%dx)
 80488fb:	70 20                	jo     804891d <_IO_stdin_used+0xf1>
 80488fd:	25 64 20 28 25       	and    $0x25282064,%eax
 8048902:	64                   	fs
 8048903:	2c 20                	sub    $0x20,%al
 8048905:	25 64 29 20 3d       	and    $0x3d202964,%eax
 804890a:	20 25 64 0a 00 46    	and    %ah,0x46000a64
 8048910:	55                   	push   %ebp
 8048911:	4e                   	dec    %esi
 8048912:	43                   	inc    %ebx
 8048913:	3a 20                	cmp    (%eax),%ah
 8048915:	6f                   	outsl  %ds:(%esi),(%dx)
 8048916:	70 20                	jo     8048938 <_IO_stdin_used+0x10c>
 8048918:	25 64 20 28 25       	and    $0x25282064,%eax
 804891d:	64                   	fs
 804891e:	2c 20                	sub    $0x20,%al
 8048920:	25 64 29 20 3d       	and    $0x3d202964,%eax
 8048925:	20 25 64 0a 00 47    	and    %ah,0x47000a64
 804892b:	4f                   	dec    %edi
 804892c:	54                   	push   %esp
 804892d:	4f                   	dec    %edi
 804892e:	3a 20                	cmp    (%eax),%ah
 8048930:	6f                   	outsl  %ds:(%esi),(%dx)
 8048931:	70 20                	jo     8048953 <_IO_stdin_used+0x127>
 8048933:	25 64 20 28 25       	and    $0x25282064,%eax
 8048938:	64                   	fs
 8048939:	2c 20                	sub    $0x20,%al
 804893b:	25 64 29 20 3d       	and    $0x3d202964,%eax
 8048940:	20                   	.byte 0x20
 8048941:	25                   	.byte 0x25
 8048942:	64 0a 00             	or     %fs:(%eax),%al

Disassembly of section .eh_frame_hdr:

08048948 <.eh_frame_hdr>:
 8048948:	01 1b                	add    %ebx,(%ebx)
 804894a:	03 3b                	add    (%ebx),%edi
 804894c:	90                   	nop
 804894d:	00 00                	add    %al,(%eax)
 804894f:	00 11                	add    %dl,(%ecx)
 8048951:	00 00                	add    %al,(%eax)
 8048953:	00 ec                	add    %ch,%ah
 8048955:	fa                   	cli    
 8048956:	ff                   	(bad)  
 8048957:	ff ac 00 00 00 57 fb 	ljmp   *-0x4a90000(%eax,%eax,1)
 804895e:	ff                   	(bad)  
 804895f:	ff cc                	dec    %esp
 8048961:	00 00                	add    %al,(%eax)
 8048963:	00 9e fb ff ff ec    	add    %bl,-0x13000005(%esi)
 8048969:	00 00                	add    %al,(%eax)
 804896b:	00 4e fc             	add    %cl,-0x4(%esi)
 804896e:	ff                   	(bad)  
 804896f:	ff 0c 01             	decl   (%ecx,%eax,1)
 8048972:	00 00                	add    %al,(%eax)
 8048974:	5b                   	pop    %ebx
 8048975:	fc                   	cld    
 8048976:	ff                   	(bad)  
 8048977:	ff 2c 01             	ljmp   *(%ecx,%eax,1)
 804897a:	00 00                	add    %al,(%eax)
 804897c:	6c                   	insb   (%dx),%es:(%edi)
 804897d:	fc                   	cld    
 804897e:	ff                   	(bad)  
 804897f:	ff 4c 01 00          	decl   0x0(%ecx,%eax,1)
 8048983:	00 78 fc             	add    %bh,-0x4(%eax)
 8048986:	ff                   	(bad)  
 8048987:	ff 6c 01 00          	ljmp   *0x0(%ecx,%eax,1)
 804898b:	00 88 fc ff ff 8c    	add    %cl,-0x73000004(%eax)
 8048991:	01 00                	add    %eax,(%eax)
 8048993:	00 a9 fc ff ff ac    	add    %ch,-0x53000004(%ecx)
 8048999:	01 00                	add    %eax,(%eax)
 804899b:	00 f0                	add    %dh,%al
 804899d:	fc                   	cld    
 804899e:	ff                   	(bad)  
 804899f:	ff cc                	dec    %esp
 80489a1:	01 00                	add    %eax,(%eax)
 80489a3:	00 30                	add    %dh,(%eax)
 80489a5:	fd                   	std    
 80489a6:	ff                   	(bad)  
 80489a7:	ff ec                	ljmp   *<internal disassembler error>
 80489a9:	01 00                	add    %eax,(%eax)
 80489ab:	00 6d fd             	add    %ch,-0x3(%ebp)
 80489ae:	ff                   	(bad)  
 80489af:	ff 0c 02             	decl   (%edx,%eax,1)
 80489b2:	00 00                	add    %al,(%eax)
 80489b4:	b4 fd                	mov    $0xfd,%ah
 80489b6:	ff                   	(bad)  
 80489b7:	ff 2c 02             	ljmp   *(%edx,%eax,1)
 80489ba:	00 00                	add    %al,(%eax)
 80489bc:	f4                   	hlt    
 80489bd:	fd                   	std    
 80489be:	ff                   	(bad)  
 80489bf:	ff 4c 02 00          	decl   0x0(%edx,%eax,1)
 80489c3:	00 18                	add    %bl,(%eax)
 80489c5:	fe                   	(bad)  
 80489c6:	ff                   	(bad)  
 80489c7:	ff 6c 02 00          	ljmp   *0x0(%edx,%eax,1)
 80489cb:	00 88 fe ff ff a8    	add    %cl,-0x57000002(%eax)
 80489d1:	02 00                	add    (%eax),%al
 80489d3:	00 8a fe ff ff bc    	add    %cl,-0x43000002(%edx)
 80489d9:	02 00                	add    (%eax),%al
	...

Disassembly of section .eh_frame:

080489dc <__FRAME_END__-0x23c>:
 80489dc:	14 00                	adc    $0x0,%al
 80489de:	00 00                	add    %al,(%eax)
 80489e0:	00 00                	add    %al,(%eax)
 80489e2:	00 00                	add    %al,(%eax)
 80489e4:	01 7a 52             	add    %edi,0x52(%edx)
 80489e7:	00 01                	add    %al,(%ecx)
 80489e9:	7c 08                	jl     80489f3 <_IO_stdin_used+0x1c7>
 80489eb:	01 1b                	add    %ebx,(%ebx)
 80489ed:	0c 04                	or     $0x4,%al
 80489ef:	04 88                	add    $0x88,%al
 80489f1:	01 00                	add    %eax,(%eax)
 80489f3:	00 1c 00             	add    %bl,(%eax,%eax,1)
 80489f6:	00 00                	add    %al,(%eax)
 80489f8:	1c 00                	sbb    $0x0,%al
 80489fa:	00 00                	add    %al,(%eax)
 80489fc:	38 fa                	cmp    %bh,%dl
 80489fe:	ff                   	(bad)  
 80489ff:	ff 6b 00             	ljmp   *0x0(%ebx)
 8048a02:	00 00                	add    %al,(%eax)
 8048a04:	00 41 0e             	add    %al,0xe(%ecx)
 8048a07:	08 85 02 42 0d 05    	or     %al,0x50d4202(%ebp)
 8048a0d:	02 67 c5             	add    -0x3b(%edi),%ah
 8048a10:	0c 04                	or     $0x4,%al
 8048a12:	04 00                	add    $0x0,%al
 8048a14:	1c 00                	sbb    $0x0,%al
 8048a16:	00 00                	add    %al,(%eax)
 8048a18:	3c 00                	cmp    $0x0,%al
 8048a1a:	00 00                	add    %al,(%eax)
 8048a1c:	83 fa ff             	cmp    $0xffffffff,%edx
 8048a1f:	ff 47 00             	incl   0x0(%edi)
 8048a22:	00 00                	add    %al,(%eax)
 8048a24:	00 41 0e             	add    %al,0xe(%ecx)
 8048a27:	08 85 02 42 0d 05    	or     %al,0x50d4202(%ebp)
 8048a2d:	02 43 c5             	add    -0x3b(%ebx),%al
 8048a30:	0c 04                	or     $0x4,%al
 8048a32:	04 00                	add    $0x0,%al
 8048a34:	1c 00                	sbb    $0x0,%al
 8048a36:	00 00                	add    %al,(%eax)
 8048a38:	5c                   	pop    %esp
 8048a39:	00 00                	add    %al,(%eax)
 8048a3b:	00 aa fa ff ff b0    	add    %ch,-0x4f000006(%edx)
 8048a41:	00 00                	add    %al,(%eax)
 8048a43:	00 00                	add    %al,(%eax)
 8048a45:	41                   	inc    %ecx
 8048a46:	0e                   	push   %cs
 8048a47:	08 85 02 42 0d 05    	or     %al,0x50d4202(%ebp)
 8048a4d:	02 ac c5 0c 04 04 00 	add    0x4040c(%ebp,%eax,8),%ch
 8048a54:	1c 00                	sbb    $0x0,%al
 8048a56:	00 00                	add    %al,(%eax)
 8048a58:	7c 00                	jl     8048a5a <_IO_stdin_used+0x22e>
 8048a5a:	00 00                	add    %al,(%eax)
 8048a5c:	3a fb                	cmp    %bl,%bh
 8048a5e:	ff                   	(bad)  
 8048a5f:	ff 0d 00 00 00 00    	decl   0x0
 8048a65:	41                   	inc    %ecx
 8048a66:	0e                   	push   %cs
 8048a67:	08 85 02 42 0d 05    	or     %al,0x50d4202(%ebp)
 8048a6d:	49                   	dec    %ecx
 8048a6e:	0c 04                	or     $0x4,%al
 8048a70:	04 c5                	add    $0xc5,%al
 8048a72:	00 00                	add    %al,(%eax)
 8048a74:	1c 00                	sbb    $0x0,%al
 8048a76:	00 00                	add    %al,(%eax)
 8048a78:	9c                   	pushf  
 8048a79:	00 00                	add    %al,(%eax)
 8048a7b:	00 27                	add    %ah,(%edi)
 8048a7d:	fb                   	sti    
 8048a7e:	ff                   	(bad)  
 8048a7f:	ff 11                	call   *(%ecx)
 8048a81:	00 00                	add    %al,(%eax)
 8048a83:	00 00                	add    %al,(%eax)
 8048a85:	41                   	inc    %ecx
 8048a86:	0e                   	push   %cs
 8048a87:	08 85 02 42 0d 05    	or     %al,0x50d4202(%ebp)
 8048a8d:	4d                   	dec    %ebp
 8048a8e:	0c 04                	or     $0x4,%al
 8048a90:	04 c5                	add    $0xc5,%al
 8048a92:	00 00                	add    %al,(%eax)
 8048a94:	1c 00                	sbb    $0x0,%al
 8048a96:	00 00                	add    %al,(%eax)
 8048a98:	bc 00 00 00 18       	mov    $0x18000000,%esp
 8048a9d:	fb                   	sti    
 8048a9e:	ff                   	(bad)  
 8048a9f:	ff 0c 00             	decl   (%eax,%eax,1)
 8048aa2:	00 00                	add    %al,(%eax)
 8048aa4:	00 41 0e             	add    %al,0xe(%ecx)
 8048aa7:	08 85 02 42 0d 05    	or     %al,0x50d4202(%ebp)
 8048aad:	48                   	dec    %eax
 8048aae:	0c 04                	or     $0x4,%al
 8048ab0:	04 c5                	add    $0xc5,%al
 8048ab2:	00 00                	add    %al,(%eax)
 8048ab4:	1c 00                	sbb    $0x0,%al
 8048ab6:	00 00                	add    %al,(%eax)
 8048ab8:	dc 00                	faddl  (%eax)
 8048aba:	00 00                	add    %al,(%eax)
 8048abc:	04 fb                	add    $0xfb,%al
 8048abe:	ff                   	(bad)  
 8048abf:	ff 10                	call   *(%eax)
 8048ac1:	00 00                	add    %al,(%eax)
 8048ac3:	00 00                	add    %al,(%eax)
 8048ac5:	41                   	inc    %ecx
 8048ac6:	0e                   	push   %cs
 8048ac7:	08 85 02 42 0d 05    	or     %al,0x50d4202(%ebp)
 8048acd:	4c                   	dec    %esp
 8048ace:	0c 04                	or     $0x4,%al
 8048ad0:	04 c5                	add    $0xc5,%al
 8048ad2:	00 00                	add    %al,(%eax)
 8048ad4:	1c 00                	sbb    $0x0,%al
 8048ad6:	00 00                	add    %al,(%eax)
 8048ad8:	fc                   	cld    
 8048ad9:	00 00                	add    %al,(%eax)
 8048adb:	00 f4                	add    %dh,%ah
 8048add:	fa                   	cli    
 8048ade:	ff                   	(bad)  
 8048adf:	ff 21                	jmp    *(%ecx)
 8048ae1:	00 00                	add    %al,(%eax)
 8048ae3:	00 00                	add    %al,(%eax)
 8048ae5:	41                   	inc    %ecx
 8048ae6:	0e                   	push   %cs
 8048ae7:	08 85 02 42 0d 05    	or     %al,0x50d4202(%ebp)
 8048aed:	5d                   	pop    %ebp
 8048aee:	c5 0c 04             	lds    (%esp,%eax,1),%ecx
 8048af1:	04 00                	add    $0x0,%al
 8048af3:	00 1c 00             	add    %bl,(%eax,%eax,1)
 8048af6:	00 00                	add    %al,(%eax)
 8048af8:	1c 01                	sbb    $0x1,%al
 8048afa:	00 00                	add    %al,(%eax)
 8048afc:	f5                   	cmc    
 8048afd:	fa                   	cli    
 8048afe:	ff                   	(bad)  
 8048aff:	ff 47 00             	incl   0x0(%edi)
 8048b02:	00 00                	add    %al,(%eax)
 8048b04:	00 41 0e             	add    %al,0xe(%ecx)
 8048b07:	08 85 02 42 0d 05    	or     %al,0x50d4202(%ebp)
 8048b0d:	02 43 c5             	add    -0x3b(%ebx),%al
 8048b10:	0c 04                	or     $0x4,%al
 8048b12:	04 00                	add    $0x0,%al
 8048b14:	1c 00                	sbb    $0x0,%al
 8048b16:	00 00                	add    %al,(%eax)
 8048b18:	3c 01                	cmp    $0x1,%al
 8048b1a:	00 00                	add    %al,(%eax)
 8048b1c:	1c fb                	sbb    $0xfb,%al
 8048b1e:	ff                   	(bad)  
 8048b1f:	ff 40 00             	incl   0x0(%eax)
 8048b22:	00 00                	add    %al,(%eax)
 8048b24:	00 41 0e             	add    %al,0xe(%ecx)
 8048b27:	08 85 02 42 0d 05    	or     %al,0x50d4202(%ebp)
 8048b2d:	7c c5                	jl     8048af4 <_IO_stdin_used+0x2c8>
 8048b2f:	0c 04                	or     $0x4,%al
 8048b31:	04 00                	add    $0x0,%al
 8048b33:	00 1c 00             	add    %bl,(%eax,%eax,1)
 8048b36:	00 00                	add    %al,(%eax)
 8048b38:	5c                   	pop    %esp
 8048b39:	01 00                	add    %eax,(%eax)
 8048b3b:	00 3c fb             	add    %bh,(%ebx,%edi,8)
 8048b3e:	ff                   	(bad)  
 8048b3f:	ff                   	(bad)  
 8048b40:	3d 00 00 00 00       	cmp    $0x0,%eax
 8048b45:	41                   	inc    %ecx
 8048b46:	0e                   	push   %cs
 8048b47:	08 85 02 42 0d 05    	or     %al,0x50d4202(%ebp)
 8048b4d:	79 0c                	jns    8048b5b <_IO_stdin_used+0x32f>
 8048b4f:	04 04                	add    $0x4,%al
 8048b51:	c5 00                	lds    (%eax),%eax
 8048b53:	00 1c 00             	add    %bl,(%eax,%eax,1)
 8048b56:	00 00                	add    %al,(%eax)
 8048b58:	7c 01                	jl     8048b5b <_IO_stdin_used+0x32f>
 8048b5a:	00 00                	add    %al,(%eax)
 8048b5c:	59                   	pop    %ecx
 8048b5d:	fb                   	sti    
 8048b5e:	ff                   	(bad)  
 8048b5f:	ff 47 00             	incl   0x0(%edi)
 8048b62:	00 00                	add    %al,(%eax)
 8048b64:	00 41 0e             	add    %al,0xe(%ecx)
 8048b67:	08 85 02 42 0d 05    	or     %al,0x50d4202(%ebp)
 8048b6d:	02 43 c5             	add    -0x3b(%ebx),%al
 8048b70:	0c 04                	or     $0x4,%al
 8048b72:	04 00                	add    $0x0,%al
 8048b74:	1c 00                	sbb    $0x0,%al
 8048b76:	00 00                	add    %al,(%eax)
 8048b78:	9c                   	pushf  
 8048b79:	01 00                	add    %eax,(%eax)
 8048b7b:	00 80 fb ff ff 40    	add    %al,0x40fffffb(%eax)
 8048b81:	00 00                	add    %al,(%eax)
 8048b83:	00 00                	add    %al,(%eax)
 8048b85:	41                   	inc    %ecx
 8048b86:	0e                   	push   %cs
 8048b87:	08 85 02 42 0d 05    	or     %al,0x50d4202(%ebp)
 8048b8d:	7c c5                	jl     8048b54 <_IO_stdin_used+0x328>
 8048b8f:	0c 04                	or     $0x4,%al
 8048b91:	04 00                	add    $0x0,%al
 8048b93:	00 1c 00             	add    %bl,(%eax,%eax,1)
 8048b96:	00 00                	add    %al,(%eax)
 8048b98:	bc 01 00 00 a0       	mov    $0xa0000001,%esp
 8048b9d:	fb                   	sti    
 8048b9e:	ff                   	(bad)  
 8048b9f:	ff 1c 00             	lcall  *(%eax,%eax,1)
 8048ba2:	00 00                	add    %al,(%eax)
 8048ba4:	00 41 0e             	add    %al,0xe(%ecx)
 8048ba7:	08 85 02 42 0d 05    	or     %al,0x50d4202(%ebp)
 8048bad:	58                   	pop    %eax
 8048bae:	c5 0c 04             	lds    (%esp,%eax,1),%ecx
 8048bb1:	04 00                	add    $0x0,%al
 8048bb3:	00 38                	add    %bh,(%eax)
 8048bb5:	00 00                	add    %al,(%eax)
 8048bb7:	00 dc                	add    %bl,%ah
 8048bb9:	01 00                	add    %eax,(%eax)
 8048bbb:	00 a4 fb ff ff 61 00 	add    %ah,0x61ffff(%ebx,%edi,8)
 8048bc2:	00 00                	add    %al,(%eax)
 8048bc4:	00 41 0e             	add    %al,0xe(%ecx)
 8048bc7:	08 85 02 41 0e 0c    	or     %al,0xc0e4102(%ebp)
 8048bcd:	87 03                	xchg   %eax,(%ebx)
 8048bcf:	41                   	inc    %ecx
 8048bd0:	0e                   	push   %cs
 8048bd1:	10 86 04 41 0e 14    	adc    %al,0x140e4104(%esi)
 8048bd7:	83 05 4e 0e 30 02 4a 	addl   $0x4a,0x2300e4e
 8048bde:	0e                   	push   %cs
 8048bdf:	14 41                	adc    $0x41,%al
 8048be1:	0e                   	push   %cs
 8048be2:	10 c3                	adc    %al,%bl
 8048be4:	41                   	inc    %ecx
 8048be5:	0e                   	push   %cs
 8048be6:	0c c6                	or     $0xc6,%al
 8048be8:	41                   	inc    %ecx
 8048be9:	0e                   	push   %cs
 8048bea:	08 c7                	or     %al,%bh
 8048bec:	41                   	inc    %ecx
 8048bed:	0e                   	push   %cs
 8048bee:	04 c5                	add    $0xc5,%al
 8048bf0:	10 00                	adc    %al,(%eax)
 8048bf2:	00 00                	add    %al,(%eax)
 8048bf4:	18 02                	sbb    %al,(%edx)
 8048bf6:	00 00                	add    %al,(%eax)
 8048bf8:	d8 fb                	fdivr  %st(3),%st
 8048bfa:	ff                   	(bad)  
 8048bfb:	ff 02                	incl   (%edx)
 8048bfd:	00 00                	add    %al,(%eax)
 8048bff:	00 00                	add    %al,(%eax)
 8048c01:	00 00                	add    %al,(%eax)
 8048c03:	00 10                	add    %dl,(%eax)
 8048c05:	00 00                	add    %al,(%eax)
 8048c07:	00 2c 02             	add    %ch,(%edx,%eax,1)
 8048c0a:	00 00                	add    %al,(%eax)
 8048c0c:	c6                   	(bad)  
 8048c0d:	fb                   	sti    
 8048c0e:	ff                   	(bad)  
 8048c0f:	ff 04 00             	incl   (%eax,%eax,1)
 8048c12:	00 00                	add    %al,(%eax)
 8048c14:	00 00                	add    %al,(%eax)
	...

08048c18 <__FRAME_END__>:
 8048c18:	00 00                	add    %al,(%eax)
	...

Disassembly of section .ctors:

08049c1c <__CTOR_LIST__>:
 8049c1c:	ff                   	(bad)  
 8049c1d:	ff                   	(bad)  
 8049c1e:	ff                   	(bad)  
 8049c1f:	ff 00                	incl   (%eax)

08049c20 <__CTOR_END__>:
 8049c20:	00 00                	add    %al,(%eax)
	...

Disassembly of section .dtors:

08049c24 <__DTOR_LIST__>:
 8049c24:	ff                   	(bad)  
 8049c25:	ff                   	(bad)  
 8049c26:	ff                   	(bad)  
 8049c27:	ff 00                	incl   (%eax)

08049c28 <__DTOR_END__>:
 8049c28:	00 00                	add    %al,(%eax)
	...

Disassembly of section .jcr:

08049c2c <__JCR_END__>:
 8049c2c:	00 00                	add    %al,(%eax)
	...

Disassembly of section .dynamic:

08049c30 <_DYNAMIC>:
 8049c30:	01 00                	add    %eax,(%eax)
 8049c32:	00 00                	add    %al,(%eax)
 8049c34:	10 00                	adc    %al,(%eax)
 8049c36:	00 00                	add    %al,(%eax)
 8049c38:	0c 00                	or     $0x0,%al
 8049c3a:	00 00                	add    %al,(%eax)
 8049c3c:	fc                   	cld    
 8049c3d:	82                   	(bad)  
 8049c3e:	04 08                	add    $0x8,%al
 8049c40:	0d 00 00 00 0c       	or     $0xc000000,%eax
 8049c45:	88 04 08             	mov    %al,(%eax,%ecx,1)
 8049c48:	04 00                	add    $0x0,%al
 8049c4a:	00 00                	add    %al,(%eax)
 8049c4c:	8c 81 04 08 f5 fe    	mov    %es,-0x10af7fc(%ecx)
 8049c52:	ff 6f bc             	ljmp   *-0x44(%edi)
 8049c55:	81 04 08 05 00 00 00 	addl   $0x5,(%eax,%ecx,1)
 8049c5c:	50                   	push   %eax
 8049c5d:	82                   	(bad)  
 8049c5e:	04 08                	add    $0x8,%al
 8049c60:	06                   	push   %es
 8049c61:	00 00                	add    %al,(%eax)
 8049c63:	00 e0                	add    %ah,%al
 8049c65:	81 04 08 0a 00 00 00 	addl   $0xa,(%eax,%ecx,1)
 8049c6c:	55                   	push   %ebp
 8049c6d:	00 00                	add    %al,(%eax)
 8049c6f:	00 0b                	add    %cl,(%ebx)
 8049c71:	00 00                	add    %al,(%eax)
 8049c73:	00 10                	add    %dl,(%eax)
 8049c75:	00 00                	add    %al,(%eax)
 8049c77:	00 15 00 00 00 00    	add    %dl,0x0
 8049c7d:	00 00                	add    %al,(%eax)
 8049c7f:	00 03                	add    %al,(%ebx)
 8049c81:	00 00                	add    %al,(%eax)
 8049c83:	00 04 9d 04 08 02 00 	add    %al,0x20804(,%ebx,4)
 8049c8a:	00 00                	add    %al,(%eax)
 8049c8c:	20 00                	and    %al,(%eax)
 8049c8e:	00 00                	add    %al,(%eax)
 8049c90:	14 00                	adc    $0x0,%al
 8049c92:	00 00                	add    %al,(%eax)
 8049c94:	11 00                	adc    %eax,(%eax)
 8049c96:	00 00                	add    %al,(%eax)
 8049c98:	17                   	pop    %ss
 8049c99:	00 00                	add    %al,(%eax)
 8049c9b:	00 dc                	add    %bl,%ah
 8049c9d:	82                   	(bad)  
 8049c9e:	04 08                	add    $0x8,%al
 8049ca0:	11 00                	adc    %eax,(%eax)
 8049ca2:	00 00                	add    %al,(%eax)
 8049ca4:	d4 82                	aam    $0xffffff82
 8049ca6:	04 08                	add    $0x8,%al
 8049ca8:	12 00                	adc    (%eax),%al
 8049caa:	00 00                	add    %al,(%eax)
 8049cac:	08 00                	or     %al,(%eax)
 8049cae:	00 00                	add    %al,(%eax)
 8049cb0:	13 00                	adc    (%eax),%eax
 8049cb2:	00 00                	add    %al,(%eax)
 8049cb4:	08 00                	or     %al,(%eax)
 8049cb6:	00 00                	add    %al,(%eax)
 8049cb8:	fe                   	(bad)  
 8049cb9:	ff                   	(bad)  
 8049cba:	ff 6f b4             	ljmp   *-0x4c(%edi)
 8049cbd:	82                   	(bad)  
 8049cbe:	04 08                	add    $0x8,%al
 8049cc0:	ff                   	(bad)  
 8049cc1:	ff                   	(bad)  
 8049cc2:	ff 6f 01             	ljmp   *0x1(%edi)
 8049cc5:	00 00                	add    %al,(%eax)
 8049cc7:	00 f0                	add    %dh,%al
 8049cc9:	ff                   	(bad)  
 8049cca:	ff 6f a6             	ljmp   *-0x5a(%edi)
 8049ccd:	82                   	(bad)  
 8049cce:	04 08                	add    $0x8,%al
	...

Disassembly of section .got:

08049d00 <.got>:
 8049d00:	00 00                	add    %al,(%eax)
	...

Disassembly of section .got.plt:

08049d04 <_GLOBAL_OFFSET_TABLE_>:
 8049d04:	30 9c 04 08 00 00 00 	xor    %bl,0x8(%esp,%eax,1)
 8049d0b:	00 00                	add    %al,(%eax)
 8049d0d:	00 00                	add    %al,(%eax)
 8049d0f:	00 42 83             	add    %al,-0x7d(%edx)
 8049d12:	04 08                	add    $0x8,%al
 8049d14:	52                   	push   %edx
 8049d15:	83 04 08 62          	addl   $0x62,(%eax,%ecx,1)
 8049d19:	83 04 08 72          	addl   $0x72,(%eax,%ecx,1)
 8049d1d:	83                   	.byte 0x83
 8049d1e:	04 08                	add    $0x8,%al

Disassembly of section .data:

08049d20 <__data_start>:
 8049d20:	00 00                	add    %al,(%eax)
	...

08049d24 <__dso_handle>:
 8049d24:	00 00                	add    %al,(%eax)
	...

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Jump table for goto_dispatch
08049d28 <labeltable.1747>:
; [OP_ADD] &&l_add
 8049d28:	87 86 04 08 91 86    	xchg   %eax,-0x796ef7fc(%esi)
; [OP_MUL] &&l_sub
 8049d2e:	04 08                	add    $0x8,%al
; [OP_SUB] &&l_mul
 8049d30:	9f                   	lahf   
 8049d31:	86 04 08             	xchg   %al,(%eax,%ecx,1)
; [OP_DIV] &&l_div
 8049d34:	a8 86                	test   $0x86,%al
 8049d36:	04 08                	add    $0x8,%al

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Jump table for func_dispatch
08049d38 <jumptable.1733>:
; Note: missing OP_ADD address! Zeroed out for now.
 8049d38:	00 00                	add    %al,(%eax)
 8049d3a:	00 00                	add    %al,(%eax)
; [OP_SUB] sub
 8049d3c:	a3 85 04 08 b4       	mov    %eax,0xb4080485
; [OP_MUL] mul
 8049d41:	85 04 08             	test   %eax,(%eax,%ecx,1)
; [OP_DIV] div
 8049d44:	c0                   	.byte 0xc0
 8049d45:	85 04 08             	test   %eax,(%eax,%ecx,1)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Disassembly of section .bss:

08049d48 <completed.5499>:
 8049d48:	00 00                	add    %al,(%eax)
	...

08049d4c <dtor_idx.5501>:
 8049d4c:	00 00                	add    %al,(%eax)
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
