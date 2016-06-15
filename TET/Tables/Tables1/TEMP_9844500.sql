﻿CREATE TABLE [dbo].[TEMP_9844500] (
    [FLD1] CHAR (13)  NOT NULL,
    [FLD2] CHAR (20)  NOT NULL,
    [FLD3] DATETIME   NOT NULL,
    [TS]   ROWVERSION NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [KEY_TSTEMP_9844500]
    ON [dbo].[TEMP_9844500]([TS] ASC);

