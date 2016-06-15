CREATE TABLE [dbo].[ViewPivotXML] (
    [Cod_indicator] CHAR (20) NOT NULL,
    [Element]       CHAR (1)  NOT NULL,
    [Date]          TEXT      NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[ViewPivotXML]([Cod_indicator] ASC, [Element] ASC);

