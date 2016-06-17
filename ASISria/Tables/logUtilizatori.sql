CREATE TABLE [dbo].[logUtilizatori] (
    [id]         INT          IDENTITY (1, 1) NOT NULL,
    [token]      VARCHAR (25) NULL,
    [utilizator] VARCHAR (40) NULL,
    [BD]         VARCHAR (40) NULL,
    [data]       DATETIME     NULL,
    [tip]        VARCHAR (1)  NULL,
    CONSTRAINT [PK_logUtilizatori] PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [princ]
    ON [dbo].[logUtilizatori]([token] ASC, [utilizator] ASC, [tip] ASC);

