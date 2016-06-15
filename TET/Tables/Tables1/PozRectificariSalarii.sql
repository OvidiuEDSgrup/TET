CREATE TABLE [dbo].[PozRectificariSalarii] (
    [idPozRectificare] INT          IDENTITY (1, 1) NOT NULL,
    [idRectificare]    INT          NULL,
    [data_rectificata] DATETIME     NULL,
    [loc_de_munca]     VARCHAR (9)  NULL,
    [tip_suma]         VARCHAR (50) NULL,
    [suma]             FLOAT (53)   NULL,
    [procent]          FLOAT (53)   NULL,
    PRIMARY KEY CLUSTERED ([idPozRectificare] ASC)
);

