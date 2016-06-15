CREATE TABLE [dbo].[D112angajatorF2] (
    [Data]         DATETIME    NULL,
    [F2_cif]       CHAR (10)   NULL,
    [F2_id]        CHAR (5)    NULL,
    [F2_suma]      CHAR (15)   NULL,
    [Loc_de_munca] VARCHAR (9) DEFAULT (NULL) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Data_id_cif]
    ON [dbo].[D112angajatorF2]([Data] ASC, [Loc_de_munca] ASC, [F2_id] ASC, [F2_cif] ASC);

