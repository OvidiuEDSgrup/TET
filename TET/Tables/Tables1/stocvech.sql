CREATE TABLE [dbo].[stocvech] (
    [Subunitate]   CHAR (9)   NOT NULL,
    [Tip_gestiune] CHAR (1)   NOT NULL,
    [Gestiune]     CHAR (9)   NOT NULL,
    [Cod]          CHAR (20)  NOT NULL,
    [Denumire]     CHAR (50)  NOT NULL,
    [Stoc1]        FLOAT (53) NOT NULL,
    [Valoare1]     FLOAT (53) NOT NULL,
    [Stoc2]        FLOAT (53) NOT NULL,
    [Valoare2]     FLOAT (53) NOT NULL,
    [Stoc3]        FLOAT (53) NOT NULL,
    [Valoare3]     FLOAT (53) NOT NULL,
    [Stoc4]        FLOAT (53) NOT NULL,
    [Valoare4]     FLOAT (53) NOT NULL,
    [Stoc5]        FLOAT (53) NOT NULL,
    [Valoare5]     FLOAT (53) NOT NULL,
    [Locm]         CHAR (9)   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Stocvech]
    ON [dbo].[stocvech]([Subunitate] ASC, [Tip_gestiune] ASC, [Gestiune] ASC, [Cod] ASC, [Locm] ASC);

