CREATE TABLE [dbo].[Antecalculatii] (
    [idAntec] INT          IDENTITY (1, 1) NOT NULL,
    [Cod]     CHAR (20)    NOT NULL,
    [Data]    DATETIME     NOT NULL,
    [Pret]    FLOAT (53)   NOT NULL,
    [valuta]  VARCHAR (10) NULL,
    [curs]    FLOAT (53)   NULL,
    [idPoz]   INT          NULL,
    [numar]   VARCHAR (20) NULL
);

