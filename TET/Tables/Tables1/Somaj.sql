CREATE TABLE [dbo].[Somaj] (
    [Luna_de_lucru] DATETIME   NOT NULL,
    [NRI]           CHAR (10)  NOT NULL,
    [DATAI]         DATETIME   NOT NULL,
    [AN]            SMALLINT   NOT NULL,
    [LN]            SMALLINT   NOT NULL,
    [DATAL]         DATETIME   NOT NULL,
    [DEN]           CHAR (60)  NOT NULL,
    [CF]            FLOAT (53) NOT NULL,
    [RJ]            CHAR (3)   NOT NULL,
    [RN]            INT        NOT NULL,
    [RA]            SMALLINT   NOT NULL,
    [NRA]           INT        NOT NULL,
    [FS]            FLOAT (53) NOT NULL,
    [TCAD]          FLOAT (53) NOT NULL,
    [TCAV]          FLOAT (53) NOT NULL,
    [TCAN]          FLOAT (53) NOT NULL,
    [DED]           FLOAT (53) NOT NULL,
    [TCID]          FLOAT (53) NOT NULL,
    [TCIV]          FLOAT (53) NOT NULL,
    [TCIN]          FLOAT (53) NOT NULL,
    [TOTD]          FLOAT (53) NOT NULL,
    [TOTV]          FLOAT (53) NOT NULL,
    [TOTN]          FLOAT (53) NOT NULL,
    [OBL]           FLOAT (53) NOT NULL,
    [OBLNA]         FLOAT (53) NOT NULL,
    [OBLNI]         FLOAT (53) NOT NULL,
    [MAJ]           FLOAT (53) NOT NULL,
    [PEN]           FLOAT (53) NOT NULL,
    [TOTOBL]        FLOAT (53) NOT NULL,
    [B1]            CHAR (30)  NOT NULL,
    [F1]            CHAR (30)  NOT NULL,
    [C1]            CHAR (30)  NOT NULL,
    [B2]            CHAR (30)  NOT NULL,
    [F2]            CHAR (30)  NOT NULL,
    [C2]            CHAR (30)  NOT NULL,
    [FUNCA]         CHAR (30)  NOT NULL,
    [NUMEA]         CHAR (30)  NOT NULL,
    [DATAD]         DATETIME   NOT NULL,
    [SUP]           SMALLINT   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Luna_de_lucru]
    ON [dbo].[Somaj]([Luna_de_lucru] ASC);

