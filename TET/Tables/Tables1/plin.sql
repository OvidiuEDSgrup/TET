CREATE TABLE [dbo].[plin] (
    [Subunitate]     CHAR (9)     NOT NULL,
    [Cont]           VARCHAR (20) NULL,
    [Data]           DATETIME     NOT NULL,
    [Numar]          VARCHAR (10) NULL,
    [Valuta]         CHAR (3)     NOT NULL,
    [Curs]           FLOAT (53)   NOT NULL,
    [Total_plati]    FLOAT (53)   NOT NULL,
    [Total_incasari] FLOAT (53)   NOT NULL,
    [Ziua]           SMALLINT     NOT NULL,
    [Numar_pozitii]  INT          NOT NULL,
    [Jurnal]         CHAR (3)     NOT NULL,
    [Stare]          SMALLINT     NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Sub_Cont_Data]
    ON [dbo].[plin]([Subunitate] ASC, [Cont] ASC, [Data] ASC, [Jurnal] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Act_plin]
    ON [dbo].[plin]([Subunitate] ASC, [Data] ASC, [Jurnal] ASC, [Cont] ASC);


GO
CREATE NONCLUSTERED INDEX [Subunitate_Data]
    ON [dbo].[plin]([Subunitate] ASC, [Data] ASC);

