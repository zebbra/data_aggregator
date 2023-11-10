export interface InjectionKey<T> extends Symbol {}

const globalProvides: Map<
  string,
  Map<InjectionKey<any> | string, any>
> = new Map();

export function provide<T, K = InjectionKey<T> | string>(
  instance: string,
  key: K,
  value: K extends InjectionKey<infer V> ? V : T
) {
  // TS doesn't allow symbol as index type
  if (!globalProvides.has(instance)) {
    globalProvides.set(instance, new Map());
  }

  const providers = globalProvides.get(instance)!;

  if (!providers.has(key as string)) {
    providers.set(key as string, new Map());
  }

  providers.set(key as string, value);
}

export function inject(
  instance: string,
  key: InjectionKey<any> | string,
  defaultValue?: any
) {
  // TS doesn't allow symbol as index type
  if (globalProvides.has(instance) && globalProvides.get(instance)!.has(key)) {
    return globalProvides.get(instance)!.get(key);
  }

  return defaultValue === undefined ? null : defaultValue;
}
