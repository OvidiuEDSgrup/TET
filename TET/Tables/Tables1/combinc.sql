CREATE TABLE [dbo].[combinc] (
    [Terminal]     SMALLINT   NOT NULL,
    [Cod]          CHAR (20)  NOT NULL,
    [Culoare]      CHAR (20)  NOT NULL,
    [Cantitate_1]  FLOAT (53) NOT NULL,
    [Cantitate_2]  FLOAT (53) NOT NULL,
    [Cantitate_3]  FLOAT (53) NOT NULL,
    [Cantitate_4]  FLOAT (53) NOT NULL,
    [Cantitate_5]  FLOAT (53) NOT NULL,
    [Cantitate_6]  FLOAT (53) NOT NULL,
    [Cantitate_7]  FLOAT (53) NOT NULL,
    [Cantitate_8]  FLOAT (53) NOT NULL,
    [Cantitate_9]  FLOAT (53) NOT NULL,
    [Cantitate_10] FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [CombiSerii]
    ON [dbo].[combinc]([Terminal] ASC, [Cod] ASC, [Culoare] ASC);

