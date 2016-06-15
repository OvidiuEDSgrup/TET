CREATE TABLE [dbo].[targetag] (
    [Agent]                CHAR (30)  NOT NULL,
    [Client]               CHAR (30)  NOT NULL,
    [Produs]               CHAR (30)  NOT NULL,
    [UM]                   CHAR (5)   NOT NULL,
    [Data_lunii]           DATETIME   NOT NULL,
    [Comision_suplimentar] FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [agent_client_produs_data]
    ON [dbo].[targetag]([Agent] ASC, [Client] ASC, [Produs] ASC, [UM] ASC, [Data_lunii] ASC);

