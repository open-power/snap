/*
 * Copyright 2017, International Business Machines
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

// this is a small compare toll for BFS output checking
#include <stdio.h>
#include <snap_tools.h>
#include <libsnap.h>

int main(int argc , char ** argv)
{
    char * hw_fname;
    char * sw_fname;
    if (argc != 3)
    {
        fprintf(stdout, "Usage: %s hw_out.bin sw_out.bin\n", argv[0]);
        exit(EXIT_FAILURE);
    }
    hw_fname = argv[1];
    sw_fname = argv[2];
    ssize_t hw_size = __file_size(hw_fname);
    ssize_t sw_size = __file_size(sw_fname);
    if(hw_size != sw_size)
    {
        fprintf(stderr, "File size not match\n");
        exit(EXIT_FAILURE);
    }
    FILE *fp1 = fopen(hw_fname, "r");
    FILE *fp2 = fopen(sw_fname, "r");
    if( fp1 == NULL || fp2 == NULL)
    {
        fprintf(stderr, "File Open Fail\n");
        exit(EXIT_FAILURE);
    }

    uint8_t hw_char, sw_char;
    int i = 0;
    int j = 0;
    while(i < hw_size)
    {
        hw_char = fgetc(fp1);
        sw_char = fgetc(fp2);
        //printf("%d.%d(%d)\n", (int)hw_char, (int)sw_char, i);

        if( (i%4 == 3) && (hw_char == 255) && (sw_char == 255))
        {
        //    printf("jump\n");
            j = 127 - (i %128);
            fseek(fp1, j, SEEK_CUR);
            fseek(fp2, j, SEEK_CUR);
            i += j;
        }


        if(hw_char != sw_char)
        {
            fprintf(stderr, "Mismatch\n");
            exit(EXIT_FAILURE);
        }

        i++;
    }
    exit(EXIT_SUCCESS);

}
