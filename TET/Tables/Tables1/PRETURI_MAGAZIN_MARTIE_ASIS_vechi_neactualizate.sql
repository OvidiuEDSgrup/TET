CREATE TABLE [dbo].[PRETURI_MAGAZIN_MARTIE_ASIS_vechi_neactualizate] (
    [Denumire]          CHAR (150) NOT NULL,
    [Cod_produs]        CHAR (20)  NOT NULL,
    [UM]                SMALLINT   NOT NULL,
    [Tip_pret]          CHAR (20)  NOT NULL,
    [Data_inferioara]   DATETIME   NOT NULL,
    [Ora_inferioara]    CHAR (13)  NOT NULL,
    [Data_superioara]   DATETIME   NOT NULL,
    [Ora_superioara]    CHAR (6)   NOT NULL,
    [Pret_vanzare]      FLOAT (53) NOT NULL,
    [Pret_cu_amanuntul] FLOAT (53) NOT NULL,
    [Utilizator]        CHAR (10)  NOT NULL,
    [Data_operarii]     DATETIME   NOT NULL,
    [Ora_operarii]      CHAR (6)   NOT NULL
);

