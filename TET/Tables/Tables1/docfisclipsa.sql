CREATE TABLE [dbo].[docfisclipsa] (
    [NrLinie]     INT          IDENTITY (1, 1) NOT NULL,
    [TipDoc]      CHAR (3)     NOT NULL,
    [Serie]       CHAR (9)     NOT NULL,
    [NumarInf]    INT          NOT NULL,
    [UltimulNr]   INT          NOT NULL,
    [NumarCurent] VARCHAR (30) NULL
);

