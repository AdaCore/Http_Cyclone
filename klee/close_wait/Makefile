CFILES = \
	$(wildcard *.c) \
	../model.c \
	../../src/cyclone_tcp/core/net.c \
	../../src/cyclone_tcp/core/tcp.c \
	../../src/common/os_port_none.c \
	../../src/cyclone_tcp/core/socket.c \
	../../src/cyclone_tcp/core/nic.c \
	../../src/cyclone_tcp/ipv4/arp.c \
	../../src/cyclone_tcp/ipv4/ipv4_frag.c \
	../../src/cyclone_tcp/ipv4/igmp.c \
	../../src/cyclone_tcp/dhcp/dhcp_client.c \
	../../src/cyclone_tcp/ipv6/ipv6_frag.c \
	../../src/cyclone_tcp/ipv6/mld.c \
	../../src/cyclone_tcp/ipv6/ndp.c \
	../../src/cyclone_tcp/dns/dns_cache.c \
	../../src/cyclone_tcp/ipv6/ipv6.c \
	../../src/cyclone_tcp/core/ethernet.c \
	../../src/cyclone_tcp/core/net_misc.c \
	../../src/cyclone_tcp/core/tcp_misc.c \
	../../src/cyclone_tcp/core/ip.c \
	../../src/cyclone_tcp/core/net_mem.c \
	../../src/common/cpu_endian.c \
	../../src/cyclone_tcp/ipv4/ipv4.c

BCFILES = $(patsubst %.c, %.bc, $(CFILES))

PATH_TO_KLEE = /home/cluzel/klee/klee/include/

INCLUDES = \
	-I../ \
	-I../../src/cyclone_tcp/ \
	-I../../src/common/ \
	-I $(PATH_TO_KLEE)

all: program.bc
	klee -warnings-only-to-file $<

%.bc: %.c
	clang-6.0 -c -g -O0 -emit-llvm $(INCLUDES) $< -o $@

program.bc: $(BCFILES)
	llvm-link-6.0 $(BCFILES) -o $@

.PHONY: clean all

clean:
	rm -rf $(BCFILES) klee-* program.bc
