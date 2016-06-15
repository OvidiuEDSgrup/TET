CREATE TABLE [dbo].[factpos] (
    [cod_fiscal]          CHAR (16) NOT NULL,
    [nr_inmatr_registru]  CHAR (20) NOT NULL,
    [denumire]            CHAR (30) NOT NULL,
    [judet]               CHAR (20) NOT NULL,
    [localitate]          CHAR (35) NOT NULL,
    [sediu]               CHAR (60) NOT NULL,
    [cont]                CHAR (35) NOT NULL,
    [banca]               CHAR (20) NOT NULL,
    [nume_delegat]        CHAR (30) NOT NULL,
    [CNP_delegat]         CHAR (16) NOT NULL,
    [serie_bi_delegat]    CHAR (4)  NOT NULL,
    [numar_bi_delegat]    CHAR (10) NOT NULL,
    [eliberat_bi_delegat] CHAR (30) NOT NULL,
    [mijloc_transport]    CHAR (10) NOT NULL,
    [nr_transport]        CHAR (15) NOT NULL,
    [data_expedierii]     DATETIME  NOT NULL,
    [ora_expedierii]      CHAR (6)  NOT NULL,
    [observatii]          CHAR (50) NOT NULL
);

