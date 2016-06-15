CREATE TABLE [dbo].[pozTehnologii_vechi] (
    [id]          INT          IDENTITY (1, 1) NOT NULL,
    [tip]         VARCHAR (1)  NOT NULL,
    [cod]         VARCHAR (20) NOT NULL,
    [cantitate]   FLOAT (53)   NULL,
    [pret]        FLOAT (53)   NULL,
    [resursa]     VARCHAR (20) NULL,
    [idp]         INT          NULL,
    [detalii]     XML          NULL,
    [cantitate_i] FLOAT (53)   NULL,
    [ordine_o]    FLOAT (53)   NULL,
    [parinteTop]  INT          NULL
);

