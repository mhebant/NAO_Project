#include <iostream>
#include <fstream>
#include <string.h>
#include <errno.h>
#include <stdlib.h>     /* strtoul */
#include <cmath> /* ceil */

#define MAX_MEM_USAGE 100000
#define FAT16_MAX_CLUSTERS 65531 // (2^16)-5
#define FAT16_MAX_SECTORS (2^32)-1

using namespace std;

extern char _bin_frankmbr_beg;

typedef struct fat16descriptor{
    char osname[8];
    unsigned short bytesPerSector;
    unsigned char sectorsPerCluster;
    unsigned short reservedSectors;
    unsigned char fatCopies;
    unsigned short rootEntries;
    unsigned short smallTotalSectors;
    unsigned char mediaDescriptor;
    unsigned short sectorsPerFat;
    unsigned short sectorsPerTrack;
    unsigned short heads;
    unsigned int hiddenSectors;
    unsigned int largeTotalSectors;
    unsigned char driveNumber;
    char gap0[1];
    unsigned char extendedBiosSignature;
    unsigned int serialNumber;
    char label[11];
    char filesystem[8];
}__attribute__((packed)) fat16descriptor;

void raw_read(char* diskname, unsigned long int offset, unsigned long int length, char* ofilename);
void raw_write(char* ifilename, unsigned long int offset, char* diskname);
void make_frank(char* diskname);

void showhelp(char* cmd = 0);

int main(int argc, char* argv[]) {
    if(argc <= 1)
        showhelp();
    else if(strcmp(argv[1], "-r") == 0 || strcmp(argv[1], "--raw-read") == 0) {
        if(argc != 6)
            cout << "Invalid parameters (try -h " << argv[1] << ")" << endl;
        else {
            char* diskname = argv[2];
            long unsigned int offset = strtoul(argv[3], nullptr, 10);
            long unsigned int length = strtoul(argv[4], nullptr, 10);
            char* ofilename = argv[5];
            raw_read(diskname, offset, length, ofilename);
        }
    }
    else if(strcmp(argv[1], "-w") == 0 || strcmp(argv[1], "--raw-write") == 0) {
        if(argc != 5)
            cout << "Invalid parameters (try -h " << argv[1] << ")" << endl;
        else {
            char* ifilename = argv[2];
            long unsigned int offset = strtoul(argv[3], nullptr, 10);
            char* diskname = argv[4];
            raw_write(ifilename, offset, diskname);
        }
    }
    else if(strcmp(argv[1], "-m") == 0 || strcmp(argv[1], "--make-frank") == 0) {
        if(argc != 3)
            cout << "Invalid parameters (try -h " << argv[1] << ")" << endl;
        else {
            char* diskname = argv[2];
            make_frank(diskname);
        }
    }
    else if(strcmp(argv[1], "-h") == 0 || strcmp(argv[1], "--help") == 0) {
        if(argc > 2)
            showhelp(argv[2]);
        else
            showhelp();
    }
    else
        cout << "Invalid command (try -h)" << endl;

    return 0;
}

void raw_read(char* diskname, unsigned long int offset, unsigned long int length, char* ofilename) {
    fstream disk;
    fstream ofile;
    
    disk.open(diskname, ios_base::in | ios_base::binary | ios_base::ate);
    if(!disk.is_open()) {
        cout << "Unable to access the disk (" << diskname << "): " << strerror(errno) << endl;
        return;
    }
    ofile.open(ofilename, ios_base::out | ios_base::binary | ios_base::trunc);
    if(!ofile.is_open()) {
        cout << "Unable to access the output file (" << ofilename << "): " << strerror(errno) << endl;
        return;
    }
    
    long unsigned int disksize = disk.tellg();
    if(offset + length > disksize) {
        cout << "Trying to read out of the disk (offset=" << offset << ", length=" << length << ", disksize=" << disksize << ")" << endl;
        return;
    }
    
    char buffer[MAX_MEM_USAGE];
    disk.seekg(offset, ios_base::beg);
    while(!disk.eof() && length > MAX_MEM_USAGE) {
        disk.read(buffer, MAX_MEM_USAGE);
        if(disk.fail()) {
            cout << "Error reading the disk: " << strerror(errno);
            return;
        }
        ofile.write(buffer, MAX_MEM_USAGE);
        if(ofile.fail()) {
            cout << "Error writing the file: " << strerror(errno);
            return;
        }
        length -= MAX_MEM_USAGE;
    }
    disk.read(buffer, length);
    if(disk.fail()) {
        cout << "Error reading the disk: " << strerror(errno);
        return;
    }
    ofile.write(buffer, length);
    if(ofile.fail()) {
        cout << "Error writing the file: " << strerror(errno);
        return;
    }
}

void raw_write(char* ifilename, unsigned long int offset, char* diskname) {
    fstream ifile;
    fstream disk;

    ifile.open(ifilename, ios_base::in | ios_base::binary | ios_base::ate);
    if(!ifile.is_open()) {
        cout << "Unable to access the input file (" << ifilename << "): " << strerror(errno) << endl;
        return;
    }
    disk.open(diskname, ios_base::out | ios_base::binary | ios_base::ate);
    if(!disk.is_open()) {
        cout << "Unable to access the disk (" << diskname << "): " << strerror(errno) << endl;
        return;
    }
    
    long unsigned int ifilesize = ifile.tellg();
    long unsigned int disksize = disk.tellp();
    if(offset + ifilesize > disksize) {
        cout << "Trying to write out of the disk (offset=" << offset << ", filesize=" << ifilesize << ", disksize=" << disksize << ")" << endl;
        return;
    }
    
    cout << "Are you sure you want to write " << ifilesize << "bytes to " << diskname << " at offset " << offset << " ?(y or n)" << endl;
    if(cin.get() != 'y')
        return;
    
    char buffer[MAX_MEM_USAGE];
    ifile.seekg(0, ios_base::beg);
    disk.seekp(offset, ios_base::beg);
    while(!disk.eof() && ifilesize > MAX_MEM_USAGE) {
        ifile.read(buffer, MAX_MEM_USAGE);
        if(ifile.fail()) {
            cout << "Error reading the file: " << strerror(errno);
            return;
        }
        disk.write(buffer, MAX_MEM_USAGE);
        if(disk.fail()) {
            cout << "Error writing the disk: " << strerror(errno);
            return;
        }
        ifilesize -= MAX_MEM_USAGE;
    }
    ifile.read(buffer, ifilesize);
    if(ifile.fail()) {
        cout << "Error reading the file: " << strerror(errno);
        return;
    }
    disk.write(buffer, ifilesize);
    if(disk.fail()) {
        cout << "Error writing the disk: " << strerror(errno);
        return;
    }
}

void make_frank(char* diskname) {
    fstream disk;
    
    disk.open(diskname, ios_base::in | ios_base::out | ios_base::binary | ios_base::ate);
    if(!disk.is_open()) {
        cout << "Unable to access the disk (" << diskname << "): " << strerror(errno) << endl;
        return;
    }
    
    long unsigned int disksize = disk.tellg();
    char* frankmbr = &_bin_frankmbr_beg;
    fat16descriptor* frankfat16 = (fat16descriptor*)(frankmbr + 3);
    if(disksize > FAT16_MAX_SECTORS * frankfat16->bytesPerSector)
        cout << diskname << " is too big. Frank can't be install on drives bigger than " << FAT16_MAX_SECTORS * frankfat16->bytesPerSector << "bytes." << endl;
    unsigned int totalSectors = disksize / frankfat16->bytesPerSector;
    if(totalSectors < 65536) // drivesize < 32Mb
        frankfat16->smallTotalSectors = totalSectors;
    else
        frankfat16->largeTotalSectors = totalSectors;
    
    unsigned int rootdirSectors = ceil(frankfat16->rootEntries * 32 / (float)frankfat16->bytesPerSector);
    unsigned int clusters = FAT16_MAX_CLUSTERS;
    while(true) {
        int sectorsPerCluster = (totalSectors - 1 - frankfat16->fatCopies - rootdirSectors) / clusters;
        if(sectorsPerCluster >= 128)
            frankfat16->sectorsPerCluster = 128;
        else if(sectorsPerCluster >= 32)
            frankfat16->sectorsPerCluster = 32;
        else if(sectorsPerCluster >= 16)
            frankfat16->sectorsPerCluster = 16;
        else if(sectorsPerCluster >= 8)
            frankfat16->sectorsPerCluster = 8;
        else if(sectorsPerCluster >= 4)
            frankfat16->sectorsPerCluster = 4;
        else if(sectorsPerCluster >= 2)
            frankfat16->sectorsPerCluster = 2;
        else
            frankfat16->sectorsPerCluster = 1;
        frankfat16->sectorsPerFat = (unsigned short)ceil((clusters * 2 + 4) / (float)frankfat16->bytesPerSector);
        long int reservedSectors = totalSectors - (clusters * frankfat16->sectorsPerCluster) - (frankfat16->fatCopies * frankfat16->sectorsPerFat) - rootdirSectors;
        cout << reservedSectors << endl;
        if(reservedSectors >= 1) {
            frankfat16->reservedSectors = reservedSectors;
            break;
        }
        clusters--;
    }
    
    cout << "You are about to bring " << diskname << " to life !! This will format the disk. Are you sure you want this ?(y or n)" << endl;
    if(cin.get() != 'y')
        return;
    
    disk.seekp(0, ios_base::beg);
    disk.write(frankmbr, 512);
    
    cout << "It's alive! It's alive!" << endl;
}

void showhelp(char* cmd) {
    if(cmd == 0) {
        cout << "rokytool v0.1" << endl;
        cout << endl;
        cout << "Tool to acess raw data of disks" << endl;
        cout << "Type -h [command] for more informations (exemple: -h -r)" << endl;
        cout << endl;
        cout << "Commands:" << endl;
        cout << "-r  --raw-read    Read raw data from a disk" << endl;
        cout << "-w  --raw-write   Write raw data to a disk" << endl;
        cout << "-h  --help        Display this help message" << endl;
    }
    else if(strcmp(cmd, "-r") == 0 || strcmp(cmd, "--raw-read") == 0) {
        cout << "Read raw data from a disk" << endl;
        cout << endl;
        cout << "Usage:" << endl;
        cout << "-r <diskname> <offset> <length> <filename>" << endl;
        cout << endl;
        cout << "<diskname>    Name of the disk to read (ex: /dev/sdb)" << endl;
        cout << "<offset>      Offset from the begining of the disk in byte (ex: 123)" << endl;
        cout << "<length>      Length to read in byte (ex: 179)" << endl;
        cout << "<filename>    Path to the file to store the data (ex: ./data.bin)" << endl;
    }
    else {
        cout << "Unknown command " << cmd << " (try -h)" << endl;
    }
    
}
