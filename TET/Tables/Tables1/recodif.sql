CREATE TABLE [dbo].[recodif] (
    [Identificator] INT       IDENTITY (1, 1) NOT NULL,
    [Tip]           CHAR (20) NOT NULL,
    [Alfa1]         CHAR (20) NOT NULL,
    [Alfa2]         CHAR (20) NOT NULL,
    [Alfa3]         CHAR (20) NOT NULL,
    [Alfa4]         CHAR (20) NOT NULL,
    [Alfa5]         CHAR (20) NOT NULL,
    [Alfa6]         CHAR (20) NOT NULL,
    [Alfa7]         CHAR (20) NOT NULL,
    [Alfa8]         CHAR (20) NOT NULL,
    [Alfa9]         CHAR (20) NOT NULL,
    [Alfa10]        CHAR (20) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic_ID]
    ON [dbo].[recodif]([Identificator] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Unic_Tip_Alfa]
    ON [dbo].[recodif]([Tip] ASC, [Alfa1] ASC, [Alfa2] ASC, [Alfa3] ASC, [Alfa4] ASC, [Alfa5] ASC, [Alfa6] ASC, [Alfa7] ASC, [Alfa8] ASC, [Alfa9] ASC, [Alfa10] ASC);

