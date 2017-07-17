/*
 * Copyright 2016, 2017, International Business Machines
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2015 Markku-Juhani O. Saarinen
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

/*
 * Example to use the FPGA to calculate a CRC32 checksum.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <errno.h>
#include <string.h>

#include <libsnap.h>
#include <snap_internal.h>
#include <action_checksum.h>
#include <sha3.h>

static int mmio_write32(struct snap_card *card,
			uint64_t offs, uint32_t data)
{
	act_trace("  %s(%p, %llx, %x)\n", __func__, card,
		  (long long)offs, data);
	return 0;
}

static int mmio_read32(struct snap_card *card,
		       uint64_t offs, uint32_t *data)
{
	act_trace("  %s(%p, %llx, %x)\n", __func__, card,
		  (long long)offs, *data);
	return 0;
}

/* Table of CRCs of all 8-bit messages. */
#if defined(CONFIG_BUILD_CRC_TABLE)

static unsigned long crc_table[256];

/* Flag: has the table been computed? Initially false. */
static int crc_table_computed = 0;

/* Make the table for a fast CRC. */
static void make_crc_table(void)
{
	unsigned long c;
	int n, k;

	for (n = 0; n < 256; n++) {
		c = (unsigned long) n;
		for (k = 0; k < 8; k++) {
			if (c & 1) {
				c = 0xedb88320L ^ (c >> 1);
			} else {
				c = c >> 1;
			}
		}
		crc_table[n] = c;
	}
	crc_table_computed = 1;
}

static void dump_crc_table(void)
{
	int i;

	printf("static unsigned long crc_table[] = {\n");
	for (i = 0; i < 256; i++) {
		printf(" 0x%08lx,", (long)crc_table[i]);
		if ((i & 3) == 3)
			printf("\n");
	}
	printf("};\n");
}

#else

static unsigned long crc_table[] = {
	0x00000000, 0x77073096, 0xee0e612c, 0x990951ba,
	0x076dc419, 0x706af48f, 0xe963a535, 0x9e6495a3,
	0x0edb8832, 0x79dcb8a4, 0xe0d5e91e, 0x97d2d988,
	0x09b64c2b, 0x7eb17cbd, 0xe7b82d07, 0x90bf1d91,
	0x1db71064, 0x6ab020f2, 0xf3b97148, 0x84be41de,
	0x1adad47d, 0x6ddde4eb, 0xf4d4b551, 0x83d385c7,
	0x136c9856, 0x646ba8c0, 0xfd62f97a, 0x8a65c9ec,
	0x14015c4f, 0x63066cd9, 0xfa0f3d63, 0x8d080df5,
	0x3b6e20c8, 0x4c69105e, 0xd56041e4, 0xa2677172,
	0x3c03e4d1, 0x4b04d447, 0xd20d85fd, 0xa50ab56b,
	0x35b5a8fa, 0x42b2986c, 0xdbbbc9d6, 0xacbcf940,
	0x32d86ce3, 0x45df5c75, 0xdcd60dcf, 0xabd13d59,
	0x26d930ac, 0x51de003a, 0xc8d75180, 0xbfd06116,
	0x21b4f4b5, 0x56b3c423, 0xcfba9599, 0xb8bda50f,
	0x2802b89e, 0x5f058808, 0xc60cd9b2, 0xb10be924,
	0x2f6f7c87, 0x58684c11, 0xc1611dab, 0xb6662d3d,
	0x76dc4190, 0x01db7106, 0x98d220bc, 0xefd5102a,
	0x71b18589, 0x06b6b51f, 0x9fbfe4a5, 0xe8b8d433,
	0x7807c9a2, 0x0f00f934, 0x9609a88e, 0xe10e9818,
	0x7f6a0dbb, 0x086d3d2d, 0x91646c97, 0xe6635c01,
	0x6b6b51f4, 0x1c6c6162, 0x856530d8, 0xf262004e,
	0x6c0695ed, 0x1b01a57b, 0x8208f4c1, 0xf50fc457,
	0x65b0d9c6, 0x12b7e950, 0x8bbeb8ea, 0xfcb9887c,
	0x62dd1ddf, 0x15da2d49, 0x8cd37cf3, 0xfbd44c65,
	0x4db26158, 0x3ab551ce, 0xa3bc0074, 0xd4bb30e2,
	0x4adfa541, 0x3dd895d7, 0xa4d1c46d, 0xd3d6f4fb,
	0x4369e96a, 0x346ed9fc, 0xad678846, 0xda60b8d0,
	0x44042d73, 0x33031de5, 0xaa0a4c5f, 0xdd0d7cc9,
	0x5005713c, 0x270241aa, 0xbe0b1010, 0xc90c2086,
	0x5768b525, 0x206f85b3, 0xb966d409, 0xce61e49f,
	0x5edef90e, 0x29d9c998, 0xb0d09822, 0xc7d7a8b4,
	0x59b33d17, 0x2eb40d81, 0xb7bd5c3b, 0xc0ba6cad,
	0xedb88320, 0x9abfb3b6, 0x03b6e20c, 0x74b1d29a,
	0xead54739, 0x9dd277af, 0x04db2615, 0x73dc1683,
	0xe3630b12, 0x94643b84, 0x0d6d6a3e, 0x7a6a5aa8,
	0xe40ecf0b, 0x9309ff9d, 0x0a00ae27, 0x7d079eb1,
	0xf00f9344, 0x8708a3d2, 0x1e01f268, 0x6906c2fe,
	0xf762575d, 0x806567cb, 0x196c3671, 0x6e6b06e7,
	0xfed41b76, 0x89d32be0, 0x10da7a5a, 0x67dd4acc,
	0xf9b9df6f, 0x8ebeeff9, 0x17b7be43, 0x60b08ed5,
	0xd6d6a3e8, 0xa1d1937e, 0x38d8c2c4, 0x4fdff252,
	0xd1bb67f1, 0xa6bc5767, 0x3fb506dd, 0x48b2364b,
	0xd80d2bda, 0xaf0a1b4c, 0x36034af6, 0x41047a60,
	0xdf60efc3, 0xa867df55, 0x316e8eef, 0x4669be79,
	0xcb61b38c, 0xbc66831a, 0x256fd2a0, 0x5268e236,
	0xcc0c7795, 0xbb0b4703, 0x220216b9, 0x5505262f,
	0xc5ba3bbe, 0xb2bd0b28, 0x2bb45a92, 0x5cb36a04,
	0xc2d7ffa7, 0xb5d0cf31, 0x2cd99e8b, 0x5bdeae1d,
	0x9b64c2b0, 0xec63f226, 0x756aa39c, 0x026d930a,
	0x9c0906a9, 0xeb0e363f, 0x72076785, 0x05005713,
	0x95bf4a82, 0xe2b87a14, 0x7bb12bae, 0x0cb61b38,
	0x92d28e9b, 0xe5d5be0d, 0x7cdcefb7, 0x0bdbdf21,
	0x86d3d2d4, 0xf1d4e242, 0x68ddb3f8, 0x1fda836e,
	0x81be16cd, 0xf6b9265b, 0x6fb077e1, 0x18b74777,
	0x88085ae6, 0xff0f6a70, 0x66063bca, 0x11010b5c,
	0x8f659eff, 0xf862ae69, 0x616bffd3, 0x166ccf45,
	0xa00ae278, 0xd70dd2ee, 0x4e048354, 0x3903b3c2,
	0xa7672661, 0xd06016f7, 0x4969474d, 0x3e6e77db,
	0xaed16a4a, 0xd9d65adc, 0x40df0b66, 0x37d83bf0,
	0xa9bcae53, 0xdebb9ec5, 0x47b2cf7f, 0x30b5ffe9,
	0xbdbdf21c, 0xcabac28a, 0x53b39330, 0x24b4a3a6,
	0xbad03605, 0xcdd70693, 0x54de5729, 0x23d967bf,
	0xb3667a2e, 0xc4614ab8, 0x5d681b02, 0x2a6f2b94,
	0xb40bbe37, 0xc30c8ea1, 0x5a05df1b, 0x2d02ef8d,
};
#endif

/*
  Update a running crc with the bytes buf[0..len-1] and return
  the updated crc. The crc should be initialized to zero. Pre- and
  post-conditioning (one's complement) is performed within this
  function so it shouldn't be done by the caller. Usage example:

  unsigned long crc = 0L;

  while (read_buffer(buffer, length) != EOF) {
      crc = update_crc(crc, buffer, length);
  }
  if (crc != original_crc) error();
*/

/* Return the CRC of the bytes buf[0..len-1]. */
static unsigned long do_crc(unsigned long crc, unsigned char *buf, int len)
{
	unsigned long c = crc ^ 0xffffffffL;
	int n;

#if defined(CONFIG_BUILD_CRC_TABLE)
	if (!crc_table_computed) {
		make_crc_table();
		dump_crc_table();
	}
#endif

	for (n = 0; n < len; n++) {
		c = crc_table[(c ^ buf[n]) & 0xff] ^ (c >> 8);
	}
	return c ^ 0xffffffffL;
}


// read a hex string, return byte length or -1 on error.
static int test_hexdigit(char ch)
{
    if (ch >= '0' && ch <= '9')
        return  ch - '0';
    if (ch >= 'A' && ch <= 'F')
        return  ch - 'A' + 10;
    if (ch >= 'a' && ch <= 'f')
        return  ch - 'a' + 10;
    return -1;
}

static int test_readhex(uint8_t *buf, const char *str, int maxbytes)
{
    int i, h, l;

    for (i = 0; i < maxbytes; i++) {
/*#pragma HLS UNROLL factor=4 */
        h = test_hexdigit(str[2 * i]);
        if (h < 0)
            return i;
        l = test_hexdigit(str[2 * i + 1]);
        if (l < 0)
            return i;
        buf[i] = (h << 4) + l;
    }

    return i;
}

// returns zero on success, nonzero + stderr messages on failure

static int test_sha3()
{
        printf("FIPS 202 / SHA3  Self-Tests : \n");
    // message / digest pairs, lifted from ShortMsgKAT_SHA3-xxx.txt files
    // in the official package: https://github.com/gvanas/KeccakCodePackage
   
    const char *testvec[][2] = {
        {   // SHA3-224, corner case with 0-length message
            "",
            "6B4E03423667DBB73B6E15454F0EB1ABD4597F9A1B078E3F5B5A6BC7"
        },
        {   // SHA3-256, short message
            "9F2FCC7C90DE090D6B87CD7E9718C1EA6CB21118FC2D5DE9F97E5DB6AC1E9C10",
            "2F1A5F7159E34EA19CDDC70EBF9B81F1A66DB40615D7EAD3CC1F1B954D82A3AF"
        },
        {   // SHA3-384, exact block size
            "E35780EB9799AD4C77535D4DDB683CF33EF367715327CF4C4A58ED9CBDCDD486"
            "F669F80189D549A9364FA82A51A52654EC721BB3AAB95DCEB4A86A6AFA93826D"
            "B923517E928F33E3FBA850D45660EF83B9876ACCAFA2A9987A254B137C6E140A"
            "21691E1069413848",
            "D1C0FA85C8D183BEFF99AD9D752B263E286B477F79F0710B0103170173978133"
            "44B99DAF3BB7B1BC5E8D722BAC85943A"
        },
        {   // SHA3-512, multiblock message
            "3A3A819C48EFDE2AD914FBF00E18AB6BC4F14513AB27D0C178A188B61431E7F5"
            "623CB66B23346775D386B50E982C493ADBBFC54B9A3CD383382336A1A0B2150A"
            "15358F336D03AE18F666C7573D55C4FD181C29E6CCFDE63EA35F0ADF5885CFC0"
            "A3D84A2B2E4DD24496DB789E663170CEF74798AA1BBCD4574EA0BBA40489D764"
            "B2F83AADC66B148B4A0CD95246C127D5871C4F11418690A5DDF01246A0C80A43"
            "C70088B6183639DCFDA4125BD113A8F49EE23ED306FAAC576C3FB0C1E256671D"
            "817FC2534A52F5B439F72E424DE376F4C565CCA82307DD9EF76DA5B7C4EB7E08"
            "5172E328807C02D011FFBF33785378D79DC266F6A5BE6BB0E4A92ECEEBAEB1",
            "6E8B8BD195BDD560689AF2348BDC74AB7CD05ED8B9A57711E9BE71E9726FDA45"
            "91FEE12205EDACAF82FFBBAF16DFF9E702A708862080166C2FF6BA379BC7FFC2"
        }
    };
/*
 // SHA3-224, corner case with 0-length message
    char testvec224_0[] = "";
    char testvec224_1[] = "6B4E03423667DBB73B6E15454F0EB1ABD4597F9A1B078E3F5B5A6BC7";
    // SHA3-256, short message
    char testvec256_0[] = "9F2FCC7C90DE090D6B87CD7E9718C1EA6CB21118FC2D5DE9F97E5DB6AC1E9C10";
    char testvec256_1[] = "2F1A5F7159E34EA19CDDC70EBF9B81F1A66DB40615D7EAD3CC1F1B954D82A3AF";
    // SHA3-384, exact block size
    char testvec384_0[] = "E35780EB9799AD4C77535D4DDB683CF33EF367715327CF4C4A58ED9CBDCDD486"
                          "F669F80189D549A9364FA82A51A52654EC721BB3AAB95DCEB4A86A6AFA93826D"
                          "B923517E928F33E3FBA850D45660EF83B9876ACCAFA2A9987A254B137C6E140A"
                          "21691E1069413848";
    char testvec384_1[] = "D1C0FA85C8D183BEFF99AD9D752B263E286B477F79F0710B0103170173978133"
                          "44B99DAF3BB7B1BC5E8D722BAC85943A";
    // SHA3-512, multiblock message
      char testvec512_0[] = "3A3A819C48EFDE2AD914FBF00E18AB6BC4F14513AB27D0C178A188B61431E7F5"
                          "623CB66B23346775D386B50E982C493ADBBFC54B9A3CD383382336A1A0B2150A"
                          "15358F336D03AE18F666C7573D55C4FD181C29E6CCFDE63EA35F0ADF5885CFC0"
                          "A3D84A2B2E4DD24496DB789E663170CEF74798AA1BBCD4574EA0BBA40489D764"
                          "B2F83AADC66B148B4A0CD95246C127D5871C4F11418690A5DDF01246A0C80A43"
                          "C70088B6183639DCFDA4125BD113A8F49EE23ED306FAAC576C3FB0C1E256671D"
                          "817FC2534A52F5B439F72E424DE376F4C565CCA82307DD9EF76DA5B7C4EB7E08"
                          "5172E328807C02D011FFBF33785378D79DC266F6A5BE6BB0E4A92ECEEBAEB1";
    char testvec512_1[] = "6E8B8BD195BDD560689AF2348BDC74AB7CD05ED8B9A57711E9BE71E9726FDA45"
                          "91FEE12205EDACAF82FFBBAF16DFF9E702A708862080166C2FF6BA379BC7FFC2";
*/
    int i, fails, msg_len, sha_len;
    uint8_t sha[64], buf[64], msg[256];
    //uint64_t sha64[8], buf64[8], msg64[32];

    fails = 0;
    for (i = 0; i < 4; i++) {
 /*#pragma HLS UNROLL*/
        memset(sha, 0, sizeof(sha));
        memset(buf, 0, sizeof(buf));
        memset(msg, 0, sizeof(msg));

        msg_len = test_readhex(msg, testvec[i][0], sizeof(msg));
        sha_len = test_readhex(sha, testvec[i][1], sizeof(sha));
/* Following code is needed for HLS
        switch(i) {
        case(0) : // SHA3-224, corner case with 0-length message
                msg_len = test_readhex(msg, testvec224_0, sizeof(msg));
                sha_len = test_readhex(sha, testvec224_1, sizeof(sha));
                break;
        case(1) :// SHA3-256, short message
            msg_len = test_readhex(msg, testvec256_0, sizeof(msg));
                sha_len = test_readhex(sha, testvec256_1, sizeof(sha));
                break;
        case(2) :// SHA3-384, exact block size
            msg_len = test_readhex(msg, testvec384_0, sizeof(msg));
            sha_len = test_readhex(sha, testvec384_1, sizeof(sha));
            break;
        case(3) :// SHA3-512, multiblock message
            msg_len = test_readhex(msg, testvec512_0, sizeof(msg));
            sha_len = test_readhex(sha, testvec512_1, sizeof(sha));
            break;
        default :
                break;
        }
*/
        sha3(msg, msg_len, buf, sha_len);

        if (memcmp(sha, buf, sha_len) != 0) {
        //for(k = 0; k < sha_len; k++) {
        //        if (sha[k] != buf[k]) {
            fprintf(stderr, "[%d] SHA3-%d, len %d test FAILED.\n",
                i, sha_len * 8, msg_len);
            fails++;
        //        }
        }
    }

    return fails;
}

// test for SHAKE128 and SHAKE256

static int test_shake()
{
        printf("SHAKE128, SHAKE2563  Self-Tests : \n");
        // Test vectors have bytes 480..511 of XOF output for given inputs.
        // From http://csrc.nist.gov/groups/ST/toolkit/examples.html#aHashing
   
/*        const char testhex[4] = {
        // SHAKE128, message of length 0
        "43E41B45A653F2A5C4492C1ADD544512DDA2529833462B71A41A45BE97290B6F",
        // SHAKE256, message of length 0
        "AB0BAE316339894304E35877B0C28A9B1FD166C796B9CC258A064A8F57E27F2A",
        // SHAKE128, 1600-bit test pattern
        "44C9FB359FD56AC0A9A75A743CFF6862F17D7259AB075216C0699511643B6439",
        // SHAKE256, 1600-bit test pattern
        "6A1A9D7846436E4DCA5728B6F760EEF0CA92BF0BE5615E96959D767197A0BEEB"
        };
*/

        // SHAKE128, message of length 0
        char testhex128_0[]    = "43E41B45A653F2A5C4492C1ADD544512DDA2529833462B71A41A45BE97290B6F";
        // SHAKE256, message of length 0
        char testhex256_0[]    = "AB0BAE316339894304E35877B0C28A9B1FD166C796B9CC258A064A8F57E27F2A";
        // SHAKE128, 1600-bit test pattern
        char testhex128_1600[] = "44C9FB359FD56AC0A9A75A743CFF6862F17D7259AB075216C0699511643B6439";
        // SHAKE256, 1600-bit test pattern
        char testhex256_1600[] = "6A1A9D7846436E4DCA5728B6F760EEF0CA92BF0BE5615E96959D767197A0BEEB";
        
    int i, j, fails;
    sha3_ctx_t sha3;
    uint8_t buf[32], ref[32];


    fails = 0;

    for (i = 0; i < 4; i++) {
/*#pragma HLS UNROLL*/
        if ((i & 1) == 0) {             // test each twice
            shake128_init(&sha3);
        } else {
            shake256_init(&sha3);
        }

        if (i >= 2) {                   // 1600-bit test pattern
            memset(buf, 0xA3, 20);
            //for (j = 0; j < 20; j ++)
            //    buf[j] = 0xA3;

            for (j = 0; j < 200; j += 20)
                shake_update(&sha3, buf, 20);
        }

        shake_xof(&sha3);               // switch to extensible output

        for (j = 0; j < 512; j += 32)   // output. discard bytes 0..479
            shake_out(&sha3, buf, 32);

        // compare to reference
        //test_readhex(ref, testhex[i], sizeof(ref));
        switch(i) {
        case(0) : // SHAKE128, message of length 0
                test_readhex(ref, testhex128_0, sizeof(ref));
                        break;
        case(1) : // SHAKE256, message of length 0
                test_readhex(ref, testhex256_0, sizeof(ref));
                break;
        case(2) : // SHAKE128, 1600-bit test pattern
                test_readhex(ref, testhex128_1600, sizeof(ref));
                break;
        case(3) : // SHAKE256, 1600-bit test pattern
                test_readhex(ref, testhex256_1600, sizeof(ref));
                break;
        default :
                        break;
        }

        if (memcmp(buf, ref, 32) != 0) {
        //for(k = 0; k < 32; k++) {
/*#pragma HLS UNROLL*/
        //        if (buf[k] != ref[k]) {
            fprintf(stderr, "[%d] SHAKE%d, len %d test FAILED.\n",
                i, i & 1 ? 256 : 128, i >= 2 ? 1600 : 0);
            fails++;
         //       }
        }
    }

    return fails;
}

// test speed of the comp
static uint64_t test_speed(const uint64_t run_number,
                           const uint32_t nb_elmts, 
                           const uint32_t freq)
{
    int i;
    uint64_t st[25], x;
    //uint64_t n;
    //clock_t bg, us;

//adding this test to control number of calls of this test
    if (nb_elmts <= (run_number % freq))
         return 0;

    for (i = 0; i < 25; i++)
/*#pragma HLS UNROLL*/
        //st[i] = i;
        st[i] = i + run_number; // adding run_number to have different checksum

    //bg = clock();
    //n = 0;

    //do{
    //{
        for (i = 0; i < NB_ROUNDS; i++)
        {
            // Successive tests of sha3 taking result of previous for next process
            //sha3_keccakf(st);
                sha3_keccakf(st, st);
        }
        //n += i;
        //us = clock() - bg;
    //}
    //} while (us < 3 * CLOCKS_PER_SEC);


    x = 0;
    for (i = 0; i < 25; i++)
/*#pragma HLS PIPELINE // using UNROLL will prevent the test_speed from being synthesized !!*/
        x += st[i];


//    printf("(%016lX) %.3f Keccak-p[1600,24] / Second.\n",
//              (unsigned long) x, (CLOCKS_PER_SEC * ((double) n)) / ((double) us));

    return x;
}

#if defined(CONFIG_USE_NO_PTHREADS)
static uint64_t sha3_main(uint32_t test_choice, uint32_t nb_elmts, uint32_t freq,
                            uint32_t threads __attribute__((unused)))
{
        uint32_t run_number;
        uint64_t checksum=0;

        act_trace("%s(%d, %d)\n", __func__, nb_elmts, freq);
        act_trace("  sw: NB_TEST_RUNS=%d NB_ROUNDS=%d\n", NB_TEST_RUNS, NB_ROUNDS);
        switch(test_choice) {
        case(CHECKSUM_SPEED):
        {
                for (run_number = 0; run_number < NB_TEST_RUNS; run_number++) {
                   if (nb_elmts > (run_number % freq)) {
                       uint64_t checksum_tmp;

                       act_trace("  run_number=%d\n", run_number);
                       checksum_tmp = test_speed(run_number, nb_elmts, freq);
                       checksum ^= checksum_tmp;
                       act_trace("    %016llx %016llx\n",
                               (long long)checksum_tmp,
                               (long long)checksum);
                   }
                }
        }
                break;
        case(CHECKSUM_SHA3):
                checksum = (uint64_t)test_sha3();
                break;
        case(CHECKSUM_SHAKE):
                checksum = (uint64_t)test_shake();
                break;
        case(CHECKSUM_SHA3_SHAKE):
                checksum = (uint64_t)test_sha3();
                checksum += (uint64_t)test_shake();
                break;
        default:
                checksum = 1;
                break;
        }

        act_trace("checksum=%016llx\n", (unsigned long long)checksum);
        return checksum;
}

#else

#include <pthread.h>

struct thread_data {
        pthread_t thread_id;    /* Thread id assigned by pthread_create() */
        unsigned int run_number;
        uint32_t test_choice;
        uint32_t nb_elmts;
        uint32_t freq;
        uint64_t checksum;
        int thread_rc;
};

static struct thread_data *d;

static void *sha3_thread(void *data)
{
        struct thread_data *d = (struct thread_data *)data;

        d->checksum = 0;
        d->thread_rc = 0;
        switch(d->test_choice) {
        case(CHECKSUM_SPEED):
                d->checksum = test_speed(d->run_number, d->nb_elmts, d->freq);
                break;
        case(CHECKSUM_SHA3):
                d->checksum = (uint64_t)test_sha3();
                break;
        case(CHECKSUM_SHAKE):
                d->checksum = (uint64_t)test_shake();
                break;
        case(CHECKSUM_SHA3_SHAKE):
                d->checksum = (uint64_t)test_sha3();
                d->checksum += (uint64_t)test_shake();
                break;
        default:
                d->checksum = 1;
                break;
        }
        pthread_exit(&d->thread_rc);
}
static uint64_t sha3_main(uint32_t test_choice, uint32_t nb_elmts, uint32_t freq, uint32_t _threads)
{
       int rc;
        uint32_t run_number;
        uint64_t checksum = 0;

        if (_threads == 0) {
                fprintf(stderr, "err: Min threads must be 1\n");
                return 0;
        }

        d = calloc(_threads * sizeof(struct thread_data), 1);
        if (d == NULL) {
                fprintf(stderr, "err: No memory available\n");
                return 0;
        }

        act_trace("%s(%d, %d, %d)\n", __func__, nb_elmts, freq, _threads);
        act_trace("  NB_TEST_RUNS=%d NB_ROUNDS=%d\n", NB_TEST_RUNS, NB_ROUNDS);
        for (run_number = 0; run_number < NB_TEST_RUNS; ) {
                unsigned int i;
                unsigned int remaining_run_number = NB_TEST_RUNS - run_number;
                unsigned int threads = MIN(remaining_run_number, _threads);

                act_trace("  [X] run_number=%d remaining=%d threads=%d\n",
                          run_number, remaining_run_number, threads);

                for (i = 0; i < threads; i++) {
                        if (nb_elmts <= ((run_number + i) % freq)) 
                                continue;

                        d[i].run_number = run_number + i;
                        d[i].test_choice = test_choice;
                        d[i].nb_elmts = nb_elmts;
                        d[i].freq = freq;
                        rc = pthread_create(&d[i].thread_id, NULL,
                                            &sha3_thread, &d[i]);
                        if (rc != 0) {
                                free(d);
                                fprintf(stderr, "starting %d failed!\n", i);
                                return EXIT_FAILURE;
                        }
                }
                for (i = 0; i < threads; i++) {
                        act_trace("      run_number=%d checksum=%016llx\n",
                                  run_number + i, (long long)d[i].checksum);

                        if (nb_elmts <= ((run_number + i) % freq))
                                continue;

                        rc = pthread_join(d[i].thread_id, NULL);
                        if (rc != 0) {
                                free(d);
                                fprintf(stderr, "joining threads failed!\n");
                                return EXIT_FAILURE;
                        }
                        checksum ^= d[i].checksum;
                }
                run_number += threads;
        }

        free(d);

        act_trace("checksum=%016llx\n", (unsigned long long)checksum);
        return checksum;

}
#endif /* CONFIG_USE_NO_PTHREADS */

static int action_main(struct snap_sim_action *action, void *job,
		       unsigned int job_len)
{
	struct checksum_job *js = (struct checksum_job *)job;
	void *src;

	act_trace("%s(%p, %p, %d) [%d]\n", __func__, action, job, job_len,
		  (int)js->chk_type);

	switch (js->chk_type) {
	case CHECKSUM_SPONGE: {
		unsigned int threads;

		act_trace("test_choice=%d nb_elmts=%d freq=%d\n", js->test_choice, 
                          js->nb_elmts, js->freq);

		threads = js->nb_test_runs; /* misused for sw sim */
                if(js->test_choice == CHECKSUM_SPEED) {
                    js->nb_test_runs = NB_TEST_RUNS;
                    js->nb_rounds = NB_ROUNDS;
                    if (js->freq == 0)
                        return 0;
                }
                else {
                    js->nb_test_runs = 0;
                    js->nb_rounds = 0;
                }

                js->chk_out = sha3_main(js->test_choice, js->nb_elmts, js->freq, threads);
                break;
	}
	case CHECKSUM_CRC32:
		/* checking parameters ... */
		if (js->in.type != SNAP_ADDRTYPE_HOST_DRAM)
			return 0;

		src = (void *)js->in.addr;
		if (src == NULL)
			return 0;

		/* calculate the results ... */
		js->chk_out = do_crc(js->chk_in, src, js->in.size);
		js->chk_out &= 0xffffffff; /* 32-bit only */
		break;

	default:
		return 0;
	}

	action->job.retc = SNAP_RETC_SUCCESS;
	return 0;
}

static struct snap_sim_action action = {
	.vendor_id = SNAP_VENDOR_ID_ANY,
	.device_id = SNAP_DEVICE_ID_ANY,
	.action_type = CHECKSUM_ACTION_TYPE,

	.job = { .retc = SNAP_RETC_FAILURE, },
	.state = ACTION_IDLE,
	.main = action_main,
	.priv_data = NULL,	/* this is passed back as void *card */
	.mmio_write32 = mmio_write32,
	.mmio_read32 = mmio_read32,

	.next = NULL,
};

static void _init(void) __attribute__((constructor));

static void _init(void)
{
	snap_action_register(&action);
}
