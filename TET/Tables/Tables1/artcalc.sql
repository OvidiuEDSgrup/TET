CREATE TABLE [dbo].[artcalc] (
    [Articol_de_calculatie]    CHAR (9)  NOT NULL,
    [Ordinea_in_raport]        SMALLINT  NOT NULL,
    [Denumire]                 CHAR (30) NOT NULL,
    [Grup]                     BIT       NOT NULL,
    [Baza_pt_regia_sectiei]    BIT       NOT NULL,
    [Baza_pt_regia_generala]   BIT       NOT NULL,
    [Baza_pt_ch_aprovizionare] BIT       NOT NULL,
    [Baza_pt_ch_desfacere]     BIT       NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Articol]
    ON [dbo].[artcalc]([Articol_de_calculatie] ASC);


GO
CREATE NONCLUSTERED INDEX [Ordine]
    ON [dbo].[artcalc]([Ordinea_in_raport] ASC);

