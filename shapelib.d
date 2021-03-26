module shapelib;

import core.stdc.config;
import core.stdc.stdio;

extern (C):

/******************************************************************************
 *
 * Project:  Shapelib
 * Purpose:  Primary include file for Shapelib.
 * Author:   Frank Warmerdam, warmerdam@pobox.com
 *
 ******************************************************************************
 * Copyright (c) 1999, Frank Warmerdam
 * Copyright (c) 2012-2016, Even Rouault <even dot rouault at spatialys.com>
 *
 * This software is available under the following "MIT Style" license,
 * or at the option of the licensee under the LGPL (see COPYING).  This
 * option is discussed in more detail in shapelib.html.
 *
 * --
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 ******************************************************************************
 *
 */

/************************************************************************/
/*                        Configuration options.                        */
/************************************************************************/

/* -------------------------------------------------------------------- */
/*      Should the DBFReadStringAttribute() strip leading and           */
/*      trailing white space?                                           */
/* -------------------------------------------------------------------- */

/* -------------------------------------------------------------------- */
/*      Should we write measure values to the Multipatch object?        */
/*      Reportedly ArcView crashes if we do write it, so for now it     */
/*      is disabled.                                                    */
/* -------------------------------------------------------------------- */

/* -------------------------------------------------------------------- */
/*      SHPAPI_CALL                                                     */
/*                                                                      */
/*      The following two macros are present to allow forcing           */
/*      various calling conventions on the Shapelib API.                */
/*                                                                      */
/*      To force __stdcall conventions (needed to call Shapelib         */
/*      from Visual Basic and/or Dephi I believe) the makefile could    */
/*      be modified to define:                                          */
/*                                                                      */
/*        /DSHPAPI_CALL=__stdcall                                       */
/*                                                                      */
/*      If it is desired to force export of the Shapelib API without    */
/*      using the shapelib.def file, use the following definition.      */
/*                                                                      */
/*        /DSHAPELIB_DLLEXPORT                                          */
/*                                                                      */
/*      To get both at once it will be necessary to hack this           */
/*      include file to define:                                         */
/*                                                                      */
/*        #define SHPAPI_CALL __declspec(dllexport) __stdcall           */
/*        #define SHPAPI_CALL1 __declspec(dllexport) * __stdcall        */
/*                                                                      */
/*      The complexity of the situation is partly caused by the        */
/*      peculiar requirement of Visual C++ that __stdcall appear        */
/*      after any "*"'s in the return value of a function while the     */
/*      __declspec(dllexport) must appear before them.                  */
/* -------------------------------------------------------------------- */

/* -------------------------------------------------------------------- */
/*      Macros for controlling CVSID and ensuring they don't appear     */
/*      as unreferenced variables resulting in lots of warnings.        */
/* -------------------------------------------------------------------- */

/* -------------------------------------------------------------------- */
/*      On some platforms, additional file IO hooks are defined that    */
/*      UTF-8 encoded filenames Unicode filenames                       */
/* -------------------------------------------------------------------- */

/* -------------------------------------------------------------------- */
/*      IO/Error hook functions.                                        */
/* -------------------------------------------------------------------- */
alias SAFile = int*;

alias SAOffset = c_ulong;

struct SAHooks
{
    SAFile function (const(char)* filename, const(char)* access) FOpen;
    SAOffset function (void* p, SAOffset size, SAOffset nmemb, SAFile file) FRead;
    SAOffset function (void* p, SAOffset size, SAOffset nmemb, SAFile file) FWrite;
    SAOffset function (SAFile file, SAOffset offset, int whence) FSeek;
    SAOffset function (SAFile file) FTell;
    int function (SAFile file) FFlush;
    int function (SAFile file) FClose;
    int function (const(char)* filename) Remove;

    void function (const(char)* message) Error;
    double function (const(char)* str) Atof;
}

void SASetupDefaultHooks (SAHooks* psHooks);
void SASetupUtf8Hooks (SAHooks* psHooks);

/************************************************************************/
/*                             SHP Support.                             */
/************************************************************************/
alias SHPObject = tagSHPObject;

struct SHPInfo
{
    SAHooks sHooks;

    SAFile fpSHP;
    SAFile fpSHX;

    int nShapeType; /* SHPT_* */

    uint nFileSize; /* SHP file */

    int nRecords;
    int nMaxRecords;
    uint* panRecOffset;
    uint* panRecSize;

    double[4] adBoundsMin;
    double[4] adBoundsMax;

    int bUpdated;

    ubyte* pabyRec;
    int nBufSize;

    int bFastModeReadObject;
    ubyte* pabyObjectBuf;
    int nObjectBufSize;
    SHPObject* psCachedObject;
}

alias SHPHandle = SHPInfo*;

/* -------------------------------------------------------------------- */
/*      Shape types (nSHPType)                                          */
/* -------------------------------------------------------------------- */
enum SHPT_NULL = 0;
enum SHPT_POINT = 1;
enum SHPT_ARC = 3;
enum SHPT_POLYGON = 5;
enum SHPT_MULTIPOINT = 8;
enum SHPT_POINTZ = 11;
enum SHPT_ARCZ = 13;
enum SHPT_POLYGONZ = 15;
enum SHPT_MULTIPOINTZ = 18;
enum SHPT_POINTM = 21;
enum SHPT_ARCM = 23;
enum SHPT_POLYGONM = 25;
enum SHPT_MULTIPOINTM = 28;
enum SHPT_MULTIPATCH = 31;

/* -------------------------------------------------------------------- */
/*      Part types - everything but SHPT_MULTIPATCH just uses           */
/*      SHPP_RING.                                                      */
/* -------------------------------------------------------------------- */

enum SHPP_TRISTRIP = 0;
enum SHPP_TRIFAN = 1;
enum SHPP_OUTERRING = 2;
enum SHPP_INNERRING = 3;
enum SHPP_FIRSTRING = 4;
enum SHPP_RING = 5;

/* -------------------------------------------------------------------- */
/*      SHPObject - represents on shape (without attributes) read       */
/*      from the .shp file.                                             */
/* -------------------------------------------------------------------- */
struct tagSHPObject
{
    int nSHPType;

    int nShapeId; /* -1 is unknown/unassigned */

    int nParts;
    int* panPartStart;
    int* panPartType;

    int nVertices;
    double* padfX;
    double* padfY;
    double* padfZ;
    double* padfM;

    double dfXMin;
    double dfYMin;
    double dfZMin;
    double dfMMin;

    double dfXMax;
    double dfYMax;
    double dfZMax;
    double dfMMax;

    int bMeasureIsUsed;
    int bFastModeReadObject;
}

/* -------------------------------------------------------------------- */
/*      SHP API Prototypes                                              */
/* -------------------------------------------------------------------- */

/* If pszAccess is read-only, the fpSHX field of the returned structure */
/* will be NULL as it is not necessary to keep the SHX file open */
SHPHandle SHPOpen (const(char)* pszShapeFile, const(char)* pszAccess);
SHPHandle SHPOpenLL (
    const(char)* pszShapeFile,
    const(char)* pszAccess,
    SAHooks* psHooks);
SHPHandle SHPOpenLLEx (
    const(char)* pszShapeFile,
    const(char)* pszAccess,
    SAHooks* psHooks,
    int bRestoreSHX);

int SHPRestoreSHX (
    const(char)* pszShapeFile,
    const(char)* pszAccess,
    SAHooks* psHooks);

/* If setting bFastMode = TRUE, the content of SHPReadObject() is owned by the SHPHandle. */
/* So you cannot have 2 valid instances of SHPReadObject() simultaneously. */
/* The SHPObject padfZ and padfM members may be NULL depending on the geometry */
/* type. It is illegal to free at hand any of the pointer members of the SHPObject structure */
void SHPSetFastModeReadObject (SHPHandle hSHP, int bFastMode);

SHPHandle SHPCreate (const(char)* pszShapeFile, int nShapeType);
SHPHandle SHPCreateLL (
    const(char)* pszShapeFile,
    int nShapeType,
    SAHooks* psHooks);
void SHPGetInfo (
    SHPHandle hSHP,
    int* pnEntities,
    int* pnShapeType,
    double* padfMinBound,
    double* padfMaxBound);

SHPObject* SHPReadObject (SHPHandle hSHP, int iShape);
int SHPWriteObject (SHPHandle hSHP, int iShape, SHPObject* psObject);

void SHPDestroyObject (SHPObject* psObject);
void SHPComputeExtents (SHPObject* psObject);
SHPObject* SHPCreateObject (
    int nSHPType,
    int nShapeId,
    int nParts,
    const(int)* panPartStart,
    const(int)* panPartType,
    int nVertices,
    const(double)* padfX,
    const(double)* padfY,
    const(double)* padfZ,
    const(double)* padfM);
SHPObject* SHPCreateSimpleObject (
    int nSHPType,
    int nVertices,
    const(double)* padfX,
    const(double)* padfY,
    const(double)* padfZ);

int SHPRewindObject (SHPHandle hSHP, SHPObject* psObject);

void SHPClose (SHPHandle hSHP);
void SHPWriteHeader (SHPHandle hSHP);

const(char)* SHPTypeName (int nSHPType);
const(char)* SHPPartTypeName (int nPartType);

/* -------------------------------------------------------------------- */
/*      Shape quadtree indexing API.                                    */
/* -------------------------------------------------------------------- */

/* this can be two or four for binary or quad tree */
enum MAX_SUBNODE = 4;

/* upper limit of tree levels for automatic estimation */
enum MAX_DEFAULT_TREE_DEPTH = 12;

struct shape_tree_node
{
    /* region covered by this node */
    double[4] adfBoundsMin;
    double[4] adfBoundsMax;

    /* list of shapes stored at this node.  The papsShapeObj pointers
       or the whole list can be NULL */
    int nShapeCount;
    int* panShapeIds;
    SHPObject** papsShapeObj;

    int nSubNodes;
    shape_tree_node*[MAX_SUBNODE] apsSubNode;
}

alias SHPTreeNode = shape_tree_node;

struct SHPTree
{
    SHPHandle hSHP;

    int nMaxDepth;
    int nDimension;
    int nTotalCount;

    SHPTreeNode* psRoot;
}

SHPTree* SHPCreateTree (
    SHPHandle hSHP,
    int nDimension,
    int nMaxDepth,
    double* padfBoundsMin,
    double* padfBoundsMax);
void SHPDestroyTree (SHPTree* hTree);

int SHPWriteTree (SHPTree* hTree, const(char)* pszFilename);

int SHPTreeAddShapeId (SHPTree* hTree, SHPObject* psObject);
int SHPTreeRemoveShapeId (SHPTree* hTree, int nShapeId);

void SHPTreeTrimExtraNodes (SHPTree* hTree);

int* SHPTreeFindLikelyShapes (
    SHPTree* hTree,
    double* padfBoundsMin,
    double* padfBoundsMax,
    int*);
int SHPCheckBoundsOverlap (double*, double*, double*, double*, int);

int* SHPSearchDiskTree (
    FILE* fp,
    double* padfBoundsMin,
    double* padfBoundsMax,
    int* pnShapeCount);

struct SHPDiskTreeInfo;
alias SHPTreeDiskHandle = SHPDiskTreeInfo*;

SHPTreeDiskHandle SHPOpenDiskTree (
    const(char)* pszQIXFilename,
    SAHooks* psHooks);

void SHPCloseDiskTree (SHPTreeDiskHandle hDiskTree);

int* SHPSearchDiskTreeEx (
    SHPTreeDiskHandle hDiskTree,
    double* padfBoundsMin,
    double* padfBoundsMax,
    int* pnShapeCount);

int SHPWriteTreeLL (SHPTree* hTree, const(char)* pszFilename, SAHooks* psHooks);

/* -------------------------------------------------------------------- */
/*      SBN Search API                                                  */
/* -------------------------------------------------------------------- */

struct SBNSearchInfo;
alias SBNSearchHandle = SBNSearchInfo*;

SBNSearchHandle SBNOpenDiskTree (const(char)* pszSBNFilename, SAHooks* psHooks);

void SBNCloseDiskTree (SBNSearchHandle hSBN);

int* SBNSearchDiskTree (
    SBNSearchHandle hSBN,
    double* padfBoundsMin,
    double* padfBoundsMax,
    int* pnShapeCount);

int* SBNSearchDiskTreeInteger (
    SBNSearchHandle hSBN,
    int bMinX,
    int bMinY,
    int bMaxX,
    int bMaxY,
    int* pnShapeCount);

void SBNSearchFreeIds (int* panShapeId);

/************************************************************************/
/*                             DBF Support.                             */
/************************************************************************/
struct DBFInfo
{
    SAHooks sHooks;

    SAFile fp;

    int nRecords;

    int nRecordLength; /* Must fit on uint16 */
    int nHeaderLength; /* File header length (32) + field
       descriptor length + spare space.
       Must fit on uint16 */
    int nFields;
    int* panFieldOffset;
    int* panFieldSize;
    int* panFieldDecimals;
    char* pachFieldType;

    char* pszHeader; /* Field descriptors */

    int nCurrentRecord;
    int bCurrentRecordModified;
    char* pszCurrentRecord;

    int nWorkFieldLength;
    char* pszWorkField;

    int bNoHeader;
    int bUpdated;

    union _Anonymous_0
    {
        double dfDoubleField;
        int nIntField;
    }

    _Anonymous_0 fieldValue;

    int iLanguageDriver;
    char* pszCodePage;

    int nUpdateYearSince1900; /* 0-255 */
    int nUpdateMonth; /* 1-12 */
    int nUpdateDay; /* 1-31 */

    int bWriteEndOfFileChar; /* defaults to TRUE */

    int bRequireNextWriteSeek;
}

alias DBFHandle = DBFInfo*;

enum DBFFieldType
{
    FTString = 0,
    FTInteger = 1,
    FTDouble = 2,
    FTLogical = 3,
    FTDate = 4,
    FTInvalid = 5
}

/* Field descriptor/header size */
enum XBASE_FLDHDR_SZ = 32;
/* Shapelib read up to 11 characters, even if only 10 should normally be used */
enum XBASE_FLDNAME_LEN_READ = 11;
/* On writing, we limit to 10 characters */
enum XBASE_FLDNAME_LEN_WRITE = 10;
/* Normally only 254 characters should be used. We tolerate 255 historically */
enum XBASE_FLD_MAX_WIDTH = 255;

DBFHandle DBFOpen (const(char)* pszDBFFile, const(char)* pszAccess);
DBFHandle DBFOpenLL (
    const(char)* pszDBFFile,
    const(char)* pszAccess,
    SAHooks* psHooks);
DBFHandle DBFCreate (const(char)* pszDBFFile);
DBFHandle DBFCreateEx (const(char)* pszDBFFile, const(char)* pszCodePage);
DBFHandle DBFCreateLL (
    const(char)* pszDBFFile,
    const(char)* pszCodePage,
    SAHooks* psHooks);

int DBFGetFieldCount (DBFHandle psDBF);
int DBFGetRecordCount (DBFHandle psDBF);
int DBFAddField (
    DBFHandle hDBF,
    const(char)* pszFieldName,
    DBFFieldType eType,
    int nWidth,
    int nDecimals);

int DBFAddNativeFieldType (
    DBFHandle hDBF,
    const(char)* pszFieldName,
    char chType,
    int nWidth,
    int nDecimals);

int DBFDeleteField (DBFHandle hDBF, int iField);

int DBFReorderFields (DBFHandle psDBF, int* panMap);

int DBFAlterFieldDefn (
    DBFHandle psDBF,
    int iField,
    const(char)* pszFieldName,
    char chType,
    int nWidth,
    int nDecimals);

DBFFieldType DBFGetFieldInfo (
    DBFHandle psDBF,
    int iField,
    char* pszFieldName,
    int* pnWidth,
    int* pnDecimals);

int DBFGetFieldIndex (DBFHandle psDBF, const(char)* pszFieldName);

int DBFReadIntegerAttribute (DBFHandle hDBF, int iShape, int iField);
double DBFReadDoubleAttribute (DBFHandle hDBF, int iShape, int iField);
const(char)* DBFReadStringAttribute (DBFHandle hDBF, int iShape, int iField);
const(char)* DBFReadLogicalAttribute (DBFHandle hDBF, int iShape, int iField);
int DBFIsAttributeNULL (DBFHandle hDBF, int iShape, int iField);

int DBFWriteIntegerAttribute (
    DBFHandle hDBF,
    int iShape,
    int iField,
    int nFieldValue);
int DBFWriteDoubleAttribute (
    DBFHandle hDBF,
    int iShape,
    int iField,
    double dFieldValue);
int DBFWriteStringAttribute (
    DBFHandle hDBF,
    int iShape,
    int iField,
    const(char)* pszFieldValue);
int DBFWriteNULLAttribute (DBFHandle hDBF, int iShape, int iField);

int DBFWriteLogicalAttribute (
    DBFHandle hDBF,
    int iShape,
    int iField,
    const char lFieldValue);
int DBFWriteAttributeDirectly (
    DBFHandle psDBF,
    int hEntity,
    int iField,
    void* pValue);
const(char)* DBFReadTuple (DBFHandle psDBF, int hEntity);
int DBFWriteTuple (DBFHandle psDBF, int hEntity, void* pRawTuple);

int DBFIsRecordDeleted (DBFHandle psDBF, int iShape);
int DBFMarkRecordDeleted (DBFHandle psDBF, int iShape, int bIsDeleted);

DBFHandle DBFCloneEmpty (DBFHandle psDBF, const(char)* pszFilename);

void DBFClose (DBFHandle hDBF);
void DBFUpdateHeader (DBFHandle hDBF);
char DBFGetNativeFieldType (DBFHandle hDBF, int iField);

const(char)* DBFGetCodePage (DBFHandle psDBF);

void DBFSetLastModifiedDate (
    DBFHandle psDBF,
    int nYYSince1900,
    int nMM,
    int nDD);

void DBFSetWriteEndOfFileChar (DBFHandle psDBF, int bWriteFlag);

/* ndef SHAPEFILE_H_INCLUDED */
