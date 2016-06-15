CREATE TABLE [dbo].[Pontaj_SARA] (
    [Event_Type]           CHAR (3)  NOT NULL,
    [Internal_external]    CHAR (3)  NOT NULL,
    [Debit_credit]         CHAR (1)  NOT NULL,
    [Management_centre]    CHAR (6)  NOT NULL,
    [Unique_number]        CHAR (20) NOT NULL,
    [Data]                 CHAR (8)  NOT NULL,
    [Supplier]             CHAR (10) NOT NULL,
    [Posting]              CHAR (8)  NOT NULL,
    [Posting_type]         CHAR (2)  NOT NULL,
    [Phase]                CHAR (2)  NOT NULL,
    [Qty1]                 CHAR (15) NOT NULL,
    [Amount1]              CHAR (15) NOT NULL,
    [Unit_price1]          CHAR (15) NOT NULL,
    [Qty2]                 CHAR (15) NOT NULL,
    [Amount2]              CHAR (15) NOT NULL,
    [Unit_price2]          CHAR (15) NOT NULL,
    [Qty3]                 CHAR (15) NOT NULL,
    [Amount3]              CHAR (15) NOT NULL,
    [Unit_price3]          CHAR (15) NOT NULL,
    [Personnel_code]       CHAR (6)  NOT NULL,
    [Code_plant]           CHAR (8)  NOT NULL,
    [Code_product]         CHAR (8)  NOT NULL,
    [Delivery_note_number] CHAR (10) NOT NULL,
    [Product_number]       CHAR (30) NOT NULL,
    [Account_number]       CHAR (6)  NOT NULL,
    [Reference_SARA]       CHAR (10) NOT NULL,
    [Supply_type]          CHAR (1)  NOT NULL,
    [Code_incident]        CHAR (3)  NOT NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Unic]
    ON [dbo].[Pontaj_SARA]([Event_Type] ASC, [Internal_external] ASC, [Debit_credit] ASC, [Management_centre] ASC, [Unique_number] ASC, [Data] ASC, [Posting] ASC, [Posting_type] ASC, [Phase] ASC, [Personnel_code] ASC, [Code_plant] ASC, [Reference_SARA] ASC);

