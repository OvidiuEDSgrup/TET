CREATE TABLE [dbo].[indicatori] (
    [Cod_Indicator]      CHAR (20)     NOT NULL,
    [Denumire_Indicator] CHAR (60)     NOT NULL,
    [Expresia]           VARCHAR (MAX) NOT NULL,
    [Unitate_de_masura]  CHAR (1)      NOT NULL,
    [Expresie]           BIT           NOT NULL,
    [Descriere_expresie] CHAR (3000)   NOT NULL,
    [Total]              BIT           NOT NULL,
    [Modificat]          BIT           NOT NULL,
    [Ordine_in_raport]   SMALLINT      NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Indicator]
    ON [dbo].[indicatori]([Cod_Indicator] ASC);


GO
CREATE NONCLUSTERED INDEX [Denumire]
    ON [dbo].[indicatori]([Denumire_Indicator] ASC);


GO
CREATE NONCLUSTERED INDEX [Ordine_in_raport]
    ON [dbo].[indicatori]([Ordine_in_raport] ASC);


GO
--***
/*Pentru sters din tabela tmp_calculat la o modificare a formulei*/
create trigger tr_modifind on indicatori for insert,update,delete as

delete tmp_calculat 
from tmp_calculat 
where cod in 
(select cod_indicator from deleted union all select cod_indicator from inserted)
