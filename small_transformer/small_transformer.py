import math
import numpy as np
from itertools import product
import torch
import torch.nn as nn

# Словарь: 5 токенов
VOCAB = ['A', 'B', 'C', 'D', '|']
VOCAB_SIZE = len(VOCAB)  # 5

# Прямой и обратный маппинг
char_to_id = {ch: i for i, ch in enumerate(VOCAB)}
id_to_char = {i: ch for i, ch in enumerate(VOCAB)}

# Проверим
print(char_to_id)  # {'A': 0, 'B': 1, 'C': 2, 'D': 3, '|': 4}


def make_example(input_str):
    """
    input_str: строка из 4 символов, например 'ABAD'
    возвращает: список id длины 9, например [0,1,0,3,4,0,1,0,3]
    """
    full = input_str + '|' + input_str
    return [char_to_id[ch] for ch in full]

# Проверим
print(make_example('ABAD'))
# [0, 1, 0, 3, 4, 0, 1, 0, 3]



def build_dataset():
    examples = []
    # product('ABCD', repeat=4) генерит все 4-буквенные комбинации:
    # ('A','A','A','A'), ('A','A','A','B'), ..., ('D','D','D','D')
    for combo in product('ABCD', repeat=4):
        input_str = ''.join(combo)         # ('A','B','A','D') -> 'ABAD'
        examples.append(make_example(input_str))
    return torch.tensor(examples, dtype=torch.long)

dataset = build_dataset()
print(dataset.shape)   # torch.Size([256, 9])
print(dataset[0])      # tensor([0, 0, 0, 0, 4, 0, 0, 0, 0])  — пример для 'AAAA'
print(dataset[27])     # tensor([0, 1, 0, 3, 4, 0, 1, 0, 3])  — пример для 'ABAD'


# dataset имеет форму [256, 9]
inputs  = dataset[:, :-1]   # все примеры, токены 0..7  → форма [256, 8]
targets = dataset[:,  1:]   # все примеры, токены 1..8  → форма [256, 8]

print(inputs[27])   # tensor([0, 1, 0, 3, 4, 0, 1, 0])
print(targets[27])  # tensor([1, 0, 3, 4, 0, 1, 0, 3])


# Создаём маску длины 8 (как у inputs/targets)
loss_mask = torch.zeros(8, dtype=torch.bool)
loss_mask[3:8] = True   # включаем позиции 3, 4, 5, 6, 7

print(loss_mask)
# tensor([False, False, False,  True,  True,  True,  True,  True])


class Embedding(nn.Module):
    def __init__(self, vocab_size, max_len, d_model):
        super().__init__()
        self.token_emb = nn.Embedding(vocab_size, d_model)
        self.pos_emb   = nn.Embedding(max_len,   d_model)

    def forward(self, x):
        # x имеет форму [B, T] — токены (целые числа)
        B, T = x.shape
        positions = torch.arange(T, device=x.device)   # [0, 1, ..., T-1]
        return self.token_emb(x) + self.pos_emb(positions)



emb = Embedding(vocab_size=5, max_len=9, d_model=8)
test_input = torch.tensor([[0, 1, 0, 3, 4, 0, 1, 0]])  # один пример 'ABAD|ABA'
out = emb(test_input)
print(out.shape)   # torch.Size([1, 8, 8])



class CausalSelfAttention(nn.Module):
    def __init__(self, d_model):
        super().__init__()
        self.d_model = d_model
        # Три обучаемые линейные проекции
        self.W_q = nn.Linear(d_model, d_model, bias=False)
        self.W_k = nn.Linear(d_model, d_model, bias=False)
        self.W_v = nn.Linear(d_model, d_model, bias=False)
        # Выходная проекция
        self.W_o = nn.Linear(d_model, d_model, bias=False)


    def forward(self, x):
            # x имеет форму [B, T, d_model]
            B, T, D = x.shape

            q = self.W_q(x)   # [B, T, d_model]
            k = self.W_k(x)   # [B, T, d_model]
            v = self.W_v(x)   # [B, T, d_model]

    # Считаем attention scores: Q K^T / sqrt(d_k)
            scores = q @ k.transpose(-2, -1)             # [B, T, T]
            scores = scores / math.sqrt(D)

            # Causal mask: нижнетреугольная матрица единиц
            mask = torch.tril(torch.ones(T, T, device=x.device, dtype=torch.bool))
            scores = scores.masked_fill(~mask, float('-inf'))

    # Softmax по строкам — получаем attention pattern A
            attn = torch.softmax(scores, dim=-1)    # [B, T, T]

            # Взвешенная сумма value-векторов
            out = attn @ v                           # [B, T, d_model]

            # Финальная проекция
            out = self.W_o(out)                      # [B, T, d_model]
            return out


attn = CausalSelfAttention(d_model=8)
test_input = torch.randn(2, 8, 8)   # 2 примера, 8 позиций, 8-мерные эмбеддинги
out = attn(test_input)
print(out.shape)   # torch.Size([2, 8, 8])


class FeedForward(nn.Module):
    def __init__(self, d_model, d_ff):
        super().__init__()
        self.linear1 = nn.Linear(d_model, d_ff)
        self.linear2 = nn.Linear(d_ff, d_model)

    def forward(self, x):
        # x имеет форму [B, T, d_model]
        x = self.linear1(x)               # [B, T, d_ff]
        x = torch.relu(x)                 # [B, T, d_ff]
        x = self.linear2(x)               # [B, T, d_model]
        return x


class TransformerBlock(nn.Module):
    def __init__(self, d_model, d_ff):
        super().__init__()
        self.ln1  = nn.LayerNorm(d_model)
        self.attn = CausalSelfAttention(d_model)
        self.ln2  = nn.LayerNorm(d_model)
        self.ffn  = FeedForward(d_model, d_ff)

    def forward(self, x):
        x = x + self.attn(self.ln1(x))    # Pre-LN attention + residual
        x = x + self.ffn(self.ln2(x))     # Pre-LN FFN + residual
        return x


class TransformerLM(nn.Module):
    def __init__(self, vocab_size, max_len, d_model, d_ff):
        super().__init__()
        self.embedding = Embedding(vocab_size, max_len, d_model)
        self.block     = TransformerBlock(d_model, d_ff)
        self.ln_final  = nn.LayerNorm(d_model)
        self.head      = nn.Linear(d_model, vocab_size)

    def forward(self, x):
        # x имеет форму [B, T] — токены
        x = self.embedding(x)         # [B, T, d_model]
        x = self.block(x)             # [B, T, d_model]
        x = self.ln_final(x)          # [B, T, d_model]
        logits = self.head(x)         # [B, T, vocab_size]
        return logits


model = TransformerLM(vocab_size=5, max_len=9, d_model=8, d_ff=16)
test_input = torch.tensor([[0, 1, 0, 3, 4, 0, 1, 0]])  # 'ABAD|ABA', форма [1, 8]
logits = model(test_input)
print(logits.shape)   # torch.Size([1, 8, 5])

# Сосчитаем параметры
n_params = sum(p.numel() for p in model.parameters())
print(f"Total parameters: {n_params}")


def compute_loss(logits, targets, loss_mask):
    """
    logits:    [B, T, vocab_size] — предсказания модели
    targets:   [B, T]              — правильные id токенов
    loss_mask: [T]                 — bool, какие позиции учитывать
    """
    B, T, V = logits.shape

    # Cross-entropy ожидает форму [N, C] для logits и [N] для targets
    loss_per_token = nn.functional.cross_entropy(
        logits.reshape(B * T, V),
        targets.reshape(B * T),
        reduction='none'
    )   # [B * T]

    # Применяем маску
    loss_per_token = loss_per_token.reshape(B, T)
    mask = loss_mask.unsqueeze(0).expand(B, T)   # [B, T]
    masked_loss = loss_per_token[mask]            # одномерный тензор

    return masked_loss.mean()



# Создаём модель и оптимизатор заново (на случай повторного запуска)
torch.manual_seed(42)
model = TransformerLM(vocab_size=5, max_len=9, d_model=8, d_ff=16)
optimizer = torch.optim.Adam(model.parameters(), lr=1e-3)

# Обучение
n_epochs = 2000
loss_history = []
for epoch in range(n_epochs):
    logits = model(inputs)
    loss = compute_loss(logits, targets, loss_mask)
    optimizer.zero_grad()
    loss.backward()
    optimizer.step()
    loss_history.append(loss.item())
    if epoch % 100 == 0:
        print(f"Epoch {epoch:4d} | loss = {loss.item():.4f}")




@torch.no_grad()
def evaluate(model, inputs, targets, loss_mask):
    model.eval()
    logits = model(inputs)                # [256, 8, 5]
    predictions = logits.argmax(dim=-1)   # [256, 8]

    # Проверяем только позиции, входящие в loss_mask
    correct = (predictions == targets) & loss_mask.unsqueeze(0)
    total_positions = loss_mask.sum() * inputs.shape[0]  # 5 * 256 = 1280
    accuracy = correct.sum().item() / total_positions.item()

    model.train()
    return accuracy

acc = evaluate(model, inputs, targets, loss_mask)
print(f"Accuracy on masked positions: {acc * 100:.2f}%")