﻿CREATE TABLE [dbo].[cap27] (
    [Data]       DATETIME   NOT NULL,
    [LD]         SMALLINT   NOT NULL,
    [AD]         SMALLINT   NOT NULL,
    [DEN]        CHAR (30)  NOT NULL,
    [CF]         FLOAT (53) NOT NULL,
    [CFANT]      FLOAT (53) NOT NULL,
    [CNPA]       FLOAT (53) NOT NULL,
    [CNPAANT]    FLOAT (53) NOT NULL,
    [CAEN]       CHAR (4)   NOT NULL,
    [TARA]       CHAR (2)   NOT NULL,
    [LOC]        CHAR (30)  NOT NULL,
    [STR]        CHAR (30)  NOT NULL,
    [NRA]        CHAR (10)  NOT NULL,
    [BL]         CHAR (10)  NOT NULL,
    [SC]         CHAR (4)   NOT NULL,
    [ET]         CHAR (2)   NOT NULL,
    [AP]         CHAR (4)   NOT NULL,
    [SECT]       SMALLINT   NOT NULL,
    [JUD]        CHAR (15)  NOT NULL,
    [TEL]        FLOAT (53) NOT NULL,
    [FAX]        FLOAT (53) NOT NULL,
    [MAIL]       CHAR (50)  NOT NULL,
    [CPOST]      CHAR (6)   NOT NULL,
    [IBAN]       CHAR (24)  NOT NULL,
    [BANCA]      CHAR (30)  NOT NULL,
    [FS1]        FLOAT (53) NOT NULL,
    [FS2]        FLOAT (53) NOT NULL,
    [CAD1]       FLOAT (53) NOT NULL,
    [CAD2]       FLOAT (53) NOT NULL,
    [TCAD]       FLOAT (53) NOT NULL,
    [TCID]       FLOAT (53) NOT NULL,
    [SSRR]       FLOAT (53) NOT NULL,
    [RP]         FLOAT (53) NOT NULL,
    [RI]         FLOAT (53) NOT NULL,
    [NA]         INT        NOT NULL,
    [NI]         INT        NOT NULL,
    [NTA]        INT        NOT NULL,
    [SUB80REC]   FLOAT (53) NOT NULL,
    [SUB80RES]   FLOAT (53) NOT NULL,
    [SC80144REC] FLOAT (53) NOT NULL,
    [SC80144RES] FLOAT (53) NOT NULL,
    [SUB85REC]   FLOAT (53) NOT NULL,
    [SUB85RES]   FLOAT (53) NOT NULL,
    [SC85144REC] FLOAT (53) NOT NULL,
    [SC85144RES] FLOAT (53) NOT NULL,
    [SUB58REC]   FLOAT (53) NOT NULL,
    [DED58RES]   FLOAT (53) NOT NULL,
    [SUB116REC]  FLOAT (53) NOT NULL,
    [DED116RES]  FLOAT (53) NOT NULL,
    [RED9394REC] FLOAT (53) NOT NULL,
    [RED9394RES] FLOAT (53) NOT NULL,
    [SUB17AREC]  FLOAT (53) NOT NULL,
    [SUB17ARES]  FLOAT (53) NOT NULL,
    [SUB17BREC]  FLOAT (53) NOT NULL,
    [SUB17BRES]  FLOAT (53) NOT NULL,
    [SUB172REC]  FLOAT (53) NOT NULL,
    [SUB172RES]  FLOAT (53) NOT NULL,
    [NUMEA]      CHAR (15)  NOT NULL,
    [PRENUMEA]   CHAR (15)  NOT NULL,
    [FUNCTIA]    CHAR (15)  NOT NULL,
    [MOD]        CHAR (1)   NOT NULL,
    [NRD]        SMALLINT   NOT NULL,
    [REC]        CHAR (1)   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [CAP11]
    ON [dbo].[cap27]([Data] ASC, [REC] ASC);

