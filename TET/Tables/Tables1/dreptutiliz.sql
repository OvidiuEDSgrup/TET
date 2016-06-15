CREATE TABLE [dbo].[dreptutiliz] (
    [Tip]   CHAR (1)  NOT NULL,
    [ID]    CHAR (10) NOT NULL,
    [Drept] CHAR (10) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[dreptutiliz]([Tip] ASC, [ID] ASC, [Drept] ASC);

